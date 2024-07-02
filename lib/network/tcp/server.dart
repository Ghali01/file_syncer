import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:files_syncer/logic/controllers/host.dart';
import 'package:files_syncer/logic/controllers/transfare_server.dart';
import 'package:files_syncer/network/tcp/utils.dart';
import 'package:files_syncer/utils/functions.dart';
import 'package:flutter/foundation.dart';

class AppServer {
  static const int port = 48510;
  late ServerSocket _tcpServer;
  late StreamSubscription _serverSub;
  HostBloc bloc;
  AppServer(this.bloc) {
    ServerSocket.bind(InternetAddress.anyIPv4, port).then((value) {
      _tcpServer = value;
      _serverSub = _tcpServer.listen(_listenToConnections);
    });
  }
  void _listenToConnections(Socket conn) async {
    Stream<Uint8List> output = conn.asBroadcastStream();
    await for (Uint8List msg in output) {
      if (msg.isNotEmpty) {
        if (msg.first == OPCodes.Identification) {
          sendIdentification(conn);
        }
        if (msg.first == OPCodes.HandShake) {
          raiseConnection(msg, conn, output);
        }
      }
    }
  }

  void sendIdentification(Socket conn) async {
    String name = await getDeviceName();
    List<int> msg = [];
    msg.add(OPCodes.Identification);
    msg.addAll(utf8.encode(name));
    conn.add(msg);
  }

  void raiseConnection(
      Uint8List msg, Socket conn, Stream<Uint8List> output) async {
    List<int> data = msg.toList()..removeAt(0);
    String name = utf8.decode(data);
    await close();
    var connection =
        ClientConnectionServer(socket: conn, output: output, name: name);
    bloc.add(NewConnectionEvent(connection: connection));
  }

  Future<void> close() async {
    await _serverSub.cancel();
    await _tcpServer.close();
  }
}

class ClientConnectionServer {
  Socket socket;
  Stream<Uint8List> output;
  TransferServerBloc? bloc;
  String name;
  StreamSubscription? _subscription;
  ClientConnectionServer(
      {required this.socket, required this.output, required this.name}) {
    _listenToEvents().then((value) => null);
  }

  void sendAcceptHandshake() {
    socket.add([OPCodes.HandShake]);
  }

  void sendRejectHandshake() {
    socket.add([OPCodes.RejectHandShake]);
  }

  void sendDirectoryData(Map data) {
    String json = jsonEncode(data);
    List encodedMsg = utf8.encode(json);
    socket.add([OPCodes.DirectorySelected, ...encodedMsg, 0, 0, 0]);
  }

  int? _checkOnSuffix(List buffer) {
    List zeros = [];
    int i = 0;
    for (var byte in buffer) {
      if (byte == 0) {
        zeros.add(i);
        if (zeros.length == 3) {
          return zeros[0];
        }
      } else {
        zeros.clear();
      }
      i++;
    }
    return null;
  }

  Future<void> _listenToEvents() async {
    List<int> buffer = [];
    bool connected = true;
    _subscription = output.listen((event) {
      buffer.addAll(event);
    }, onDone: () {
      bloc?.add(ClientDisconnected());
      connected = false;
    });
    while (connected) {
      int? index = _checkOnSuffix(buffer);
      if (index != null) {
        List<int> msg = buffer.sublist(0, index);
        buffer.removeRange(0, index + 3);

        if (msg.first == OPCodes.TransferData) {
          _onTransferDataReceived(msg);
        }
        if (msg.first == OPCodes.ProgressChange) {
          _onProgressChangeReceived(msg);
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
  }

  void _onTransferDataReceived(List<int> encodedMsg) {
    String json = utf8.decode(encodedMsg.sublist(1));
    List data = jsonDecode(json);
    bloc?.add(TransferData(files: data));
  }

  void _onProgressChangeReceived(List<int> encodedMsg) {
    String json = utf8.decode(encodedMsg.sublist(1));
    Map data = jsonDecode(json);
    bloc?.add(ProgressChange(data: data));
  }

  Future<void> close() async {
    await _subscription?.cancel();

    await socket.close();
  }
}
