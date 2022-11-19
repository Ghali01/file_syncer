import 'package:bloc/bloc.dart';

import 'package:files_syncer/logic/models/host.dart';
import 'package:files_syncer/network/tcp/server.dart';

abstract class _BaseHostEvent {}

class CloseHostEvent extends _BaseHostEvent {}

abstract class _ConnectionToHostEvent extends _BaseHostEvent {
  ClientConnectionServer connection;
  _ConnectionToHostEvent({
    required this.connection,
  });
}

class NewConnectionEvent extends _ConnectionToHostEvent {
  NewConnectionEvent({required super.connection});
}

class AcceptConnectionEvent extends _ConnectionToHostEvent {
  AcceptConnectionEvent({required super.connection});
}

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
    on<CloseHostEvent>((event, emit) async {
      await server.close();
      emit(state.copyWith(closed: true));
    });
    on<RejectConnectionEvent>((event, emit) {
      event.connection.sendRejectHandshake();
    });
  }
  @override
  Future<void> close() {
    server.close();
    return super.close();
  }
}
