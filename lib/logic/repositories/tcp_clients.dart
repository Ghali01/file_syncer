import 'dart:io';

import 'package:files_syncer/network/tcp/client.dart';
import 'package:files_syncer/network/tcp/scanner.dart';
import 'package:files_syncer/network/tcp/server.dart';

class TcpClientsRepository {
  final NetworkScanner scanner;

  TcpClientsRepository(this.scanner);

  Future<List<ClientConnectionClient>> scan() async {
    List<ClientConnectionClient> devices = [];
    var stream = await scanner.scan(AppServer.port);
    // scan through the network
    await for (var address in stream) {
      try {
        print(address);
        ClientConnectionClient connection =
            ClientConnectionClient(address: address);
        // connect to the host (create channel)
        await connection.connect();
        devices.add(connection);
      } on SocketException catch (_) {}
    }

    return devices;
  }
}
