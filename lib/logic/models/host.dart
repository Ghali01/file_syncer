import 'package:files_syncer/network/tcp/server.dart';

class HostState {
  bool connected;
  bool closed;
  rerun? connection;
  HostState({
    this.connected = false,
    this.closed = false,
    this.connection,
  });

  HostState copyWith({
    bool? connected,
    bool? closed,
    rerun? connection,
  }) {
    return HostState(
      connected: connected ?? this.connected,
      closed: closed ?? this.closed,
      connection: connection ?? this.connection,
    );
  }
}
