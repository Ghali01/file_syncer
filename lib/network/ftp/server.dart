import 'package:ftp_server/ftp_server.dart' as ftp;
import 'package:ftp_server/server_type.dart';

class FTPServer {
  final String address;
  final int port;
  final String directory;
  final String user;
  final String password;
  late final ftp.FtpServer server;
  FTPServer(this.address, this.port, this.directory, this.user, this.password) {
    server = ftp.FtpServer(
      port,
      username: user,
      password: password,
      allowedDirectories: [directory],
      startingDirectory: directory,
      serverType: ServerType.readAndWrite, // or ServerType.readOnly
    );
  }
  Future<void> start() async {
    await server.start();
  }

  Future<void> stop() async {
    await server.stop();
  }
}
