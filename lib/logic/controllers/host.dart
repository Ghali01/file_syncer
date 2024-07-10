import 'package:bloc/bloc.dart';

import 'package:files_syncer/logic/states/host.dart';
import 'package:files_syncer/network/tcp/server.dart';
import 'package:files_syncer/network/tcp/server_listener.dart';

class HostBloc extends Cubit<HostState> implements IServerListener {
  final AppServer server;
  HostBloc(this.server) : super(HostState()) {
    server.listener = this;
  }

  // on close the page
  @override
  Future<void> close() async {
    await server.close(); //close host
    return await super.close();
  }

  //on a new connection comes to the server
  @override
  void onNewConnection(ClientConnectionServer connection) {
    emit(state.copyWith(connection: connection));
  }

  // accept a coming connection
  void acceptConnection(ClientConnectionServer connection) {
    connection.sendAcceptHandshake();
    emit(state.copyWith(connected: true));
  }

  // reject a coming connection
  void rejectConnection(ClientConnectionServer connection) {
    connection.sendRejectHandshake();
  }
}
