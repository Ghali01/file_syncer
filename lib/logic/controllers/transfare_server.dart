import 'dart:io';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:files_syncer/logic/models/file_model.dart';
import 'package:files_syncer/utils/notifications.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:files_syncer/logic/models/transfare_server.dart';
import 'package:files_syncer/network/ftp/server.dart';

import 'package:files_syncer/network/tcp/server.dart';

abstract class _BaseTransferServerEvent {}

// when user try to select directory
class SelectDirectoryClicked extends _BaseTransferServerEvent {}

// when receiver disconnected
class ClientDisconnected extends _BaseTransferServerEvent {}

// when receiver send the directory tree
class TransferData extends _BaseTransferServerEvent {
  List files;
  TransferData({
    required this.files,
  });
}

// when file progress is sent by the receiver
class ProgressChange extends _BaseTransferServerEvent {
  Map data;
  ProgressChange({
    required this.data,
  });
}

class TransferServerBloc
    extends Bloc<_BaseTransferServerEvent, TransferServerState> {
  rerun connection;
  FTPServer? ftpServer;
  late int
      notificationID; // the id is used  to display the progress notification
  int currentIndex =
      0; // the index of the file that currently is being received
  bool connected =
      true; // this bool will assigned to false on disconnect to remove the notification

  TransferServerBloc(this.connection) : super(TransferServerState()) {
    notificationID = Random().nextInt(1000000);
    connection.bloc = this;
    on<SelectDirectoryClicked>((event, emit) async {
      String? path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        // run the ftp server on the path
        _runFtpServer(path);
        // get the dir tree
        Map data = _dirToMap(path, Directory(path));
        // send the dir tree to the receiver
        connection.sendDirectoryData(data);
        emit(state.copyWith(path: path));
      }
    });
    on<TransferData>((event, emit) async {
      emit(
        state.copyWith(
            files: event.files.map((e) => FileModel.fromMap(e)).toList(),
            totalLength: _calcLength(event.files),
            sending: true,
            totalReceived: 0),
      );
      do {
        // Watered the speed in every second in state.speed
        // every second the value of this variable will moved to speedPerSecond
        // and the speed variable will assign to 0emit(state.copyWith(speedPerSecond: state.speed, speed: 0));
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
    });

    on<ProgressChange>((event, emit) {
      // change the state

      List files = state.files.toList();
      files[event.data['index']!] = FileModel.fromMap(event.data);
      currentIndex = event.data['index']!;
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
    });
    on<ClientDisconnected>((event, emit) =>
        emit(state.copyWith(connected: false, sending: false)));
  }
  int _calcLength(List files) {
    num sum = 0;
    for (var item in files) {
      sum += item['length']!.toInt();
    }
    return sum.toInt();
  }

  static Map _dirToMap(String prefixPath, Directory directory) {
    Map<String, dynamic> items = {
      'type': "dir",
      'path': directory.path.replaceFirst(prefixPath, '').replaceAll('\\', '/'),
    };
    List dir = directory.listSync();
    List subs = [];
    for (FileSystemEntity item in dir) {
      if (FileSystemEntity.isDirectorySync(item.absolute.path)) {
        subs.add(_dirToMap(prefixPath, item as Directory));
      }
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

  void _runFtpServer(String path) async {
    await ftpServer?.stop();
    NetworkInfo info = NetworkInfo();
    String host = (await info.getWifiIP())!;
    ftpServer = FTPServer(host, 21401, path, 'user', '1234');
    await ftpServer?.start();
  }

  @override
  Future<void> close() async {
    connected = false;
    await ftpServer?.stop();
    NotificationsManager.closeAll();
    if (state.connected) {
      await connection.close();
    }
    return await super.close();
  }
}
