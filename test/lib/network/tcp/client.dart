import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:files_syncer/logic/controllers/transform_client.dart';
import 'package:files_syncer/network/tcp/server.dart';
import 'package:files_syncer/network/tcp/utils.dart';
import 'package:files_syncer/utils/functions.dart';

class ClientConnectionClient {
  late Socket _socket;
  late Stream<Uint8List> output;
  late String name;
  String address;
  TransformClientBloc? bloc;
  StreamSubscription? _subscription;
  ClientConnectionClient({
    required this.address,
  });

  Future<void> connect() async {
    _socket = await Socket.connect(address, AppServer.port);
    output = _socket.asBroadcastStream();
    _socket.add([OPCodes.Identification]);
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
    _socket.add([OPCodes.HandShake, ...utf8.encode(name)]);
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

  int? _checkOnSufix(List buffer) {
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
  }

  Future<void> _listenToEvents() async {
    List<int> buffer = [];
    bool connected = true;
    _subscription = output.listen((event) {
      buffer.addAll(event);
      print(buffer);
    }, onDone: () {
      bloc?.add(ServerDisconnected());
      connected = false;
    });
    while (connected) {
      int? index = _checkOnSufix(buffer);
      if (index != null) {
        List<int> msg = buffer.sublist(0, index);
        buffer.removeRange(0, index + 3);
        if (msg.first == OPCodes.DirectorySelected) {
          onDirectorySelected(msg);
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
  }

  void onDirectorySelected(List<int> encodedMsg) {
    String json = utf8.decode(encodedMsg.sublist(1));
    Map data = jsonDecode(json);
    bloc?.add(DirectorySelected(data: data));
  }

  void sendTransformData(List data) {
    String json = jsonEncode(data);
    List encodedMsg = utf8.encode(json);
    _socket.add([OPCodes.TransformData, ...encodedMsg, 0, 0, 0]);
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
