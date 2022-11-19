import 'package:ftpconnect/ftpconnect.dart';
import 'package:python_channel/python_channel.dart';

void main() async {
  PythonChannelPlugin.bindHost(
      name: 'ftp',
      debugPyPath: 'E:\\projects\\files_syncer\\python\\ftp.py',
      releasePath: '');
  MethodChannel channel = MethodChannel(name: 'ftp');
  await channel.invokeMethod('start', []);
  PythonChannelPlugin.bindChannel('ftp', channel);
  FTPConnect ftpConnect =
      FTPConnect('192.168.1.5', port: 2121, user: 'user', pass: '12345');
  await ftpConnect.connect();
  List l = await ftpConnect.listDirectoryContent();
  print(l);
  await channel.invokeMethod('stop', []);
  await ftpConnect.listDirectoryContent();
}
