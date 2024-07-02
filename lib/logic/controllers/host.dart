import 'package:bloc/bloc.dart';

import 'package:files_syncer/logic/models/host.dart';
import 'package:files_syncer/network/tcp/server.dart';

abstract class _BaseHostEvent {}

// when user close the host
class CloseHostEvent extends _BaseHostEvent {}

abstract class _ConnectionToHostEvent extends _BaseHostEvent {
  rerun connection;
  _ConnectionToHostEvent({
    required this.connection,
  });
}

// new connection comes
class NewConnectionEvent extends _ConnectionToHostEvent {
  NewConnectionEvent({required super.connection});
}

// when the user accept  the connection
class AcceptConnectionEvent extends _ConnectionToHostEvent {
  AcceptConnectionEvent({required super.connection});
}

// when the user reject  the connection
class RejectConnectionEvent extends _ConnectionToHostEvent {
  RejectConnectionEvent({required super.connection});
}

class HostBloc extends Bloc<_BaseHostEvent, HostState> {
  late AppServer server;
  HostBloc() : super(HostState()) {
    server = AppServer(this);

    on<NewConnectionEvent>((event, emit) {
      emit(state.copyWith(connection: event.connection));
    });
    on<AcceptConnectionEvent>((event, emit) {
      event.connection.sendAcceptHandshake();
      emit(state.copyWith(connected: true));
    });
    on<RejectConnectionEvent>((event, emit) {
      event.connection.sendRejectHandshake();
    });
    on<CloseHostEvent>((event, emit) async {
      await server.close();
      emit(state.copyWith(closed: true));
    });
  }

  // on close the page
  @override
  Future<void> close() async {
    await server.close(); //close host
    return await super.close();
  }
}
