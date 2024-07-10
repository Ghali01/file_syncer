import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:files_syncer/network/tcp/client_listener.dart';
import 'package:files_syncer/network/tcp/server.dart';
import 'package:files_syncer/network/tcp/utils.dart';
import 'package:files_syncer/utils/functions.dart';

class ClientConnectionClient {
  late Socket _socket;
  late Stream<Uint8List> output;
  //the device name
  late String name;
  String address;
  IClientListener? listener;
  StreamSubscription? _subscription;
  ClientConnectionClient({
    required this.address,
  });

  Future<void> connect() async {
    // start the socket connection
    _socket = await Socket.connect(address, AppServer.port);
    output = _socket.asBroadcastStream();
    _socket.add([OPCodes.Identification]);
    // get the host name
    await for (Uint8List msg in output) {
      if (msg.isNotEmpty && msg.first == OPCodes.Identification) {
        List<int> data = msg.toList()..removeAt(0);
        name = utf8.decode(data);
        break;
      }
    }
  }

  Future<bool> sendHandshakeRequest() async {
    String name = await getDeviceName();
    //send the handshake  op code and the device name
    _socket.add([OPCodes.HandShake, ...utf8.encode(name)]);
    //wait the response
    await for (Uint8List msg in output) {
      if (msg.isNotEmpty) {
        if (msg.first == OPCodes.HandShake) {
          _listenToEvents().then((value) => null);
          return true;
        }
        if (msg.first == OPCodes.RejectHandShake) {
          return false;
        }
      }
    }
    return false;
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
      //add the bytes to the buffer
      buffer.addAll(event);
      print(event);
      int? index = _checkOnSuffix(buffer);
      //while there is completed messages in the buffer handle it
      while (index != null) {
        List<int> msg = buffer.sublist(0, index);
        buffer.removeRange(0, index + 3);

        if (msg.first == OPCodes.DirectorySelected) {
          _onDirectorySelected(msg);
        }
        if (msg.first == OPCodes.FileShare) {
          _onShareFile(msg);
        }
        index = _checkOnSuffix(buffer);
      }
    }, onDone: () {
      // socket disconnected
      listener?.onServerDisconnected();
    });
  }

  void _onDirectorySelected(List<int> encodedMsg) {
    String json = utf8.decode(encodedMsg.sublist(1));
    Map data = jsonDecode(json);
    listener?.onDirectorySelected(data);
  }

  void _onShareFile(List<int> encodedMsg) {
    String json = utf8.decode(encodedMsg.sublist(1));
    Map data = jsonDecode(json);
    listener?.onShareFile(data);
  }

  void sendTransferData(List data) {
    String json = jsonEncode(data);
    List encodedMsg = utf8.encode(json);
    _socket.add([OPCodes.TransferData, ...encodedMsg, 0, 0, 0]);
  }

  void sendTaskCompleted(int port) {
    String json = jsonEncode({'port': port});
    List encodedMsg = utf8.encode(json);
    _socket.add([OPCodes.TransferData, ...encodedMsg, 0, 0, 0]);
  }

  void sendProgressChange(Map data) {
    String json = jsonEncode(data);
    List encodedMsg = utf8.encode(json);
    _socket.add([OPCodes.ProgressChange, ...encodedMsg, 0, 0, 0]);
  }

  Future<void> close() async {
    await _subscription?.cancel();

    await _socket.close();
  }
}
