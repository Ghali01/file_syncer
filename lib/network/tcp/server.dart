import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:files_syncer/network/tcp/client_server_listener.dart';
import 'package:files_syncer/network/tcp/server_listener.dart';
import 'package:files_syncer/network/tcp/utils.dart';
import 'package:files_syncer/utils/functions.dart';
import 'package:flutter/foundation.dart';

/// the ftp server of the app this class starts the ftp server and start listen on the coming connection
class AppServer {
  static const int port = 48510;
  //the tcp server instance
  late ServerSocket _tcpServer;
  //a Subscription for coming connections
  late StreamSubscription _serverSub;
  IServerListener? listener;
  AppServer() {
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

//trigger when a clint find the server and request for its name
  void sendIdentification(Socket conn) async {
    String name = await getDeviceName();
    List<int> msg = [];
    msg.add(OPCodes.Identification);
    msg.addAll(utf8.encode(name));
    conn.add(msg);
  }

//trigger when a client send handshake request
  void raiseConnection(
      Uint8List msg, Socket conn, Stream<Uint8List> output) async {
    List<int> data = msg.toList()..removeAt(0);
    String name = utf8.decode(data);
    await close();
    var connection =
        ClientConnectionServer(socket: conn, output: output, name: name);
    listener?.onNewConnection(connection);
  }

  Future<void> close() async {
    await _serverSub.cancel();
    await _tcpServer.close();
  }
}

class ClientConnectionServer {
  Socket socket;
  Stream<Uint8List> output;
  IClientServerListener? listener;
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

  void sendFileShare(Map data) {
    String json = jsonEncode(data);
    List encodedMsg = utf8.encode(json);
    socket.add([OPCodes.FileShare, ...encodedMsg, 0, 0, 0]);
  }

//a method checks if there is a complete message in the buffer
//and return the index of the end of that message
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
    _subscription = output.listen((event) {
      //add the received bytes to the buffer
      buffer.addAll(event);
      //while there is completed messages in the buffer handle it
      int? index = _checkOnSuffix(buffer);
      while (index != null) {
        List<int> msg = buffer.sublist(0, index);
        buffer.removeRange(0, index + 3);
        if (msg.first == OPCodes.TransferData) {
          _onTransferDataReceived(msg);
        }
        if (msg.first == OPCodes.ProgressChange) {
          _onProgressChangeReceived(msg);
        }
        if (msg.first == OPCodes.TaskCompleted) {
          _onTaskCompletedReceived(msg);
        }
        index = _checkOnSuffix(buffer);
      }
    }, onDone: () {
      listener?.onDisconnected();
    });
  }

  void _onTransferDataReceived(List<int> encodedMsg) {
    String json = utf8.decode(encodedMsg.sublist(1));
    List data = jsonDecode(json);
    listener?.onReceiveTransferData(data);
  }

  void _onProgressChangeReceived(List<int> encodedMsg) {
    String json = utf8.decode(encodedMsg.sublist(1));
    Map data = jsonDecode(json);
    listener?.onProgressChanged(data);
  }

  void _onTaskCompletedReceived(List<int> encodedMsg) {
    String json = utf8.decode(encodedMsg.sublist(1));
    Map data = jsonDecode(json);
    listener?.onTaskCompleted(data['port']);
  }

  Future<void> close() async {
    await _subscription?.cancel();

    await socket.close();
  }
}
