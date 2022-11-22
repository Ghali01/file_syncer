import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:files_syncer/logic/models/scan.dart';
import 'package:files_syncer/network/tcp/client.dart';
import 'package:files_syncer/network/tcp/server.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';

class ScanCubit extends Cubit<ScanState> {
  ScanCubit() : super(ScanState()) {
    scan().then((value) => null);
  }
  Future<void> scan() async {
    emit(state.copyWith(scanning: true));
    // get the privet ip
    String ip;
    if (Platform.isAndroid) {
      List<NetworkInterface> ips = await NetworkInterface.list();
      ip = ips.first.addresses.first.address;
    } else {
      NetworkInfo info = NetworkInfo();
      ip = (await info.getWifiIP())!;
    }
    // get the subnet from the ip
    List l = ip.split('.')..removeLast();
    // print(ip);
    String subnet = l.join('.');
    List<ClientConnectionClient> devices = [];
    var stream = NetworkAnalyzer.discover2(subnet, AppServer.port,
        timeout: const Duration(seconds: 7));
    try {
      // scan through the network
      await for (var address in stream) {
        if (address.exists) {
          print(address.ip);
          ClientConnectionClient connection =
              ClientConnectionClient(address: address.ip);
          // connect to the host (create channel)
          await connection.connect();
          devices.add(connection);
        }
      }
    } catch (e) {}

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
