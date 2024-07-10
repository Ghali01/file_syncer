import 'dart:io';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:files_syncer/logic/models/file_model.dart';
import 'package:files_syncer/network/tcp/client_server_listener.dart';
import 'package:files_syncer/utils/notifications.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:files_syncer/logic/states/transfare_server.dart';
import 'package:files_syncer/network/ftp/server.dart';

import 'package:files_syncer/network/tcp/server.dart';

class TransferServerBloc extends Cubit<TransferServerState>
    implements IClientServerListener {
  final ClientConnectionServer connection;
  final Map<int, FTPServer> ftpServers = {};
  final int notificationID = Random()
      .nextInt(1000000); // the id is used  to display the progress notification
  int currentIndex =
      0; // the index of the file that currently is being received
  bool connected =
      true; // this bool will assigned to false on disconnect to remove the notification

  TransferServerBloc(this.connection) : super(TransferServerState()) {
    connection.listener = this;
  }

  //calculate the total of files size of a list
  int _calcLength(List files) {
    num sum = 0;
    for (var item in files) {
      sum += item['length']!.toInt();
    }
    return sum.toInt();
  }

  //create a Map structure represent the files tree in a directory
  static Map _dirToMap(String prefixPath, Directory directory) {
    //the tree root
    Map<String, dynamic> items = {
      'type': "dir",
      'path': directory.path.replaceFirst(prefixPath, '').replaceAll('\\', '/'),
    };
    //list of files and sub dirs
    List dir = directory.listSync();
    List subs = [];
    for (FileSystemEntity item in dir) {
      //if the sub is dir do recursive call
      if (FileSystemEntity.isDirectorySync(item.absolute.path)) {
        subs.add(_dirToMap(prefixPath, item as Directory));
      }
      //if is file just add it to the list
      if (FileSystemEntity.isFileSync(item.absolute.path)) {
        subs.add({
          'type': "file",
          "path": item.path.replaceFirst(prefixPath, '').replaceAll('\\', '/'),
          "length": (item as File).lengthSync()
        });
      }
    }
    items['subs'] = subs;
    return items;
  }

  int _randomPort() {
    final random = Random();
    const min = 49152;
    const max = 65535;
    final int randomPort = min + random.nextInt(max - min + 1);
    return randomPort;
  }

  Future<int> _runFtpServer(String path) async {
    final port = _randomPort();

    NetworkInfo info = NetworkInfo();
    String host = (await info.getWifiIP())!;
    final ftpServer = FTPServer(host, port, path, 'user', '1234');
    ftpServer.start();
    ftpServers[port] = ftpServer;
    return port;
  }

  @override
  Future<void> close() async {
    connected = false;

    for (var server in ftpServers.values) {
      await server.stop();
    }
    NotificationsManager.closeAll();
    if (state.connected) {
      await connection.close();
    }
    return await super.close();
  }

//on the other device is disconnected
  @override
  void onDisconnected() =>
      emit(state.copyWith(connected: false, sending: false));

//on download progress received from the client
  @override
  void onProgressChanged(Map data) {
// change the state

    List files = state.files.toList();
    files[data['index']!] = FileModel.fromMap(data);
    currentIndex = data['index']!;
    // calculate the the total size of received files
    num totalReceived = 0;
    for (var item in files) {
      totalReceived += item.totalReceived;
    }

    // Watered the speed in every second in state.speed
    // every second the value of this variable will moved to speedPerSecond
    // and the speed variable will assign to 0
    num speed = (state.speed ?? 0) + totalReceived - state.totalReceived;
    bool sending = totalReceived == state.totalLength! ? false : true;
    emit(state.copyWith(
        files: files,
        totalReceived: totalReceived.toInt(),
        sending: sending,
        speed: speed.toInt()));
  }

  //when the data of the transfer (the list of files will be transferred received)
  @override
  void onReceiveTransferData(List files) async {
    emit(
      state.copyWith(
        files: [
          ...state.files,
          ...files.map((e) => FileModel.fromMap(e)).toList()
        ],
        totalLength: (state.totalLength ?? 0) + _calcLength(files),
      ),
    );
    if (!state.sending) {
      _displayTransferData();
    }
    emit(
      state.copyWith(
        sending: true,
      ),
    );
  }

  //select folder to sync
  void selectDirectory() async {
    String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      // run the ftp server on the path
      final port = await _runFtpServer(path);
      // get the dir tree
      Map data = _dirToMap(path, Directory(path));
      data['port'] = port;
      // send the dir tree to the receiver
      connection.sendDirectoryData(data);
      emit(state.copyWith(path: path));
    }
  }

  void _displayTransferData() async {
    do {
      // Watered the speed in every second in state.speed
      // every second the value of this variable will moved to speedPerSecond
      // and the speed variable will assign to 0

      emit(state.copyWith(speedPerSecond: state.speed, speed: 0));

      NotificationsManager.show(
        notificationID,
        'Connected to ${connection.name}',
        '${state.files[currentIndex].path} | ${state.speedInSecond}',
        state.files[currentIndex].progress.toInt(),
        state.progressValue.toInt(),
      );
      await Future.delayed(const Duration(seconds: 1));
    } while (state.sending && connected);
    NotificationsManager.closeAll();
  }

  //stop the ftp server of a task when it completed
  @override
  void onTaskCompleted(int port) async {
    await ftpServers[port]?.stop();
  }
}
