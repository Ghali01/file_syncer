abstract class FTPHandler {
  final String address;
  final int port;
  final String directory;
  final String user;
  final String password;
  FTPHandler({
    required this.address,
    required this.port,
    required this.directory,
    required this.user,
    required this.password,
  });
  Future<void> start();
  Future<void> stop();
}
