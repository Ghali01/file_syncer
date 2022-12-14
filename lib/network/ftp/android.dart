import 'package:files_syncer/network/ftp/base.dart';
import 'package:flutter/services.dart';

class AndroidFTPHandler extends FTPHandler {
  // the kotlin channel
  MethodChannel channel = const MethodChannel('ftp');
  // the id of the server
  static int _count = 0;
  late String id;
  AndroidFTPHandler(
      {required super.address,
      required super.port,
      required super.directory,
      required super.user,
      required super.password}) {
    // set unique id
    _count++;
    id = 'ftp-$_count';
  }

  @override
  Future<void> start() async {
    await channel.invokeMethod('start', {
      'host': address,
      'port': port,
      'directory': directory,
      'user': user,
      'password': password,
      "id": id
    });
  }

  @override
  Future<void> stop() async {
    await channel.invokeListMethod("stop", {'id': id});
  }
}
