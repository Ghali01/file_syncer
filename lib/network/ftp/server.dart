import 'dart:io';

import 'package:files_syncer/network/ftp/android.dart';
import 'package:files_syncer/network/ftp/base.dart';
import 'package:files_syncer/network/ftp/windows.dart';

class FTPServer {
  final String address;
  final int port;
  final String directory;
  final String user;
  final String password;
  late FTPHandler _handler;
  FTPServer(this.address, this.port, this.directory, this.user, this.password) {
    if (Platform.isWindows) {
      _handler = WindowsFTPHandler(
          address: address,
          port: port,
          directory: directory,
          user: user,
          password: password);
    }
    if (Platform.isAndroid) {
      _handler = AndroidFTPHandler(
          address: address,
          port: port,
          directory: directory,
          user: user,
          password: password);
    }
  }
  Future<void> start() async {
    await _handler.start();
  }

  Future<void> stop() async {
    await _handler.stop();
  }
}
