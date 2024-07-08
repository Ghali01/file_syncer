import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:files_syncer/logic/models/scan.dart';
import 'package:files_syncer/network/tcp/client.dart';
import 'package:files_syncer/network/tcp/scanner.dart';
import 'package:files_syncer/network/tcp/server.dart';

class ScanCubit extends Cubit<ScanState> {
  ScanCubit() : super(ScanState()) {
    scan().then((value) => null);
  }
  Future<void> scan() async {
    emit(state.copyWith(scanning: true));

    List<ClientConnectionClient> devices = [];
    try {
      var stream = await NetworkScanner().scan(AppServer.port);
      // scan through the network
      await for (var address in stream) {
        print(address);
        ClientConnectionClient connection =
            ClientConnectionClient(address: address);
        // connect to the host (create channel)
        await connection.connect();
        devices.add(connection);
      }
    } on SocketException catch (_) {}

    emit(state.copyWith(scanning: false, devices: devices));
  }

  // when user select a device
  void connect(int index) async {
    emit(
        state.copyWith(connecting: true, connectTo: state.devices[index].name));
    // send handshake because channel already have created
    bool connected = await state.devices[index].sendHandshakeRequest();

    emit(state.copyWith(
        connecting: false,
        connected: connected,
        connection: state.devices[index]));
  }
}
