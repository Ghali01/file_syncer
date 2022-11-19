import 'package:files_syncer/network/tcp/client.dart';
import 'package:files_syncer/network/tcp/utils.dart';

class ScanState {
  bool scanning;
  bool connecting;
  bool connected;
  String? connectTo;
  List<ClientConnectionClient> devices;
  ClientConnectionClient? connection;
  ScanState({
    this.scanning = true,
    this.connecting = false,
    this.connected = false,
    this.connectTo,
    this.devices = const [],
    this.connection,
  });

  ScanState copyWith({
    bool? scanning,
    bool? connecting,
    bool? connected,
    String? connectTo,
    List<ClientConnectionClient>? devices,
    ClientConnectionClient? connection,
  }) {
    return ScanState(
      scanning: scanning ?? this.scanning,
      connecting: connecting ?? this.connecting,
      connected: connected ?? this.connected,
      connectTo: connectTo ?? this.connectTo,
      devices: devices ?? this.devices,
      connection: connection ?? this.connection,
    );
  }
}
