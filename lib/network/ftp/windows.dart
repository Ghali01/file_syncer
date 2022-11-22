import 'package:python_channel/python_channel.dart';

import 'base.dart';

class WindowsFTPHandler extends FTPHandler {
  // the id of the server
  static int _count = 0;
  late String _id;
  MethodChannel channel = MethodChannel(name: 'ftp');
  WindowsFTPHandler(
      {required super.address,
      required super.port,
      required super.directory,
      required super.user,
      required super.password}) {
    // set unique id
    _count++;
    _id = 'ftpH$_count';

// bind python host for each server
    PythonChannelPlugin.bindHost(
        name: _id,
        // debugExePath: 'E:\\projects\\files_syncer\\python\\dist\\ftp.exe',
        debugPyPath: 'E:\\projects\\files_syncer\\python\\ftp.py',
        releasePath: 'ftp.exe');
    PythonChannelPlugin.bindChannel(_id, channel);
  }

  @override
  Future<void> start() async {
    await channel.invokeMethod('start', {
      'host': address,
      'port': port,
      'directory': directory,
      'user': user,
      'password': password
    });
  }

  @override
  Future<void> stop() async {
    await channel.invokeMethod('stop', []);
    PythonChannelPlugin.unbindHost(_id);
  }
}
