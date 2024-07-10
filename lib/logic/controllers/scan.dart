import 'package:bloc/bloc.dart';

import 'package:files_syncer/logic/states/scan.dart';
import 'package:files_syncer/logic/repositories/tcp_clients.dart';

class ScanCubit extends Cubit<ScanState> {
  final TcpClientsRepository repository;
  ScanCubit(
    this.repository,
  ) : super(ScanState()) {
    scan().then((value) => null);
  }
  Future<void> scan() async {
    emit(state.copyWith(scanning: true));
    final devices = await repository.scan();
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
