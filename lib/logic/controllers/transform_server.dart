import 'dart:io';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:files_syncer/logic/models/file_model.dart';
import 'package:files_syncer/utils/notifications.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:files_syncer/logic/models/transform_server.dart';
import 'package:files_syncer/network/ftp/server.dart';
import 'package:files_syncer/network/tcp/client.dart';
import 'package:files_syncer/network/tcp/server.dart';

abstract class _BaseTransformServerEvent {}

class SelectDirectoryClicked extends _BaseTransformServerEvent {}

class ClientDisconnected extends _BaseTransformServerEvent {}

class TransformData extends _BaseTransformServerEvent {
  List files;
  TransformData({
    required this.files,
  });
}

class ProgressChange extends _BaseTransformServerEvent {
  Map data;
  ProgressChange({
    required this.data,
  });
}

class TransformServerBloc
    extends Bloc<_BaseTransformServerEvent, TransformServerState> {
  ClientConnectionServer connection;
  FTPServer? ftpServer;
  late int notificationID;
  int currentIndex = 0;
  TransformServerBloc(this.connection) : super(TransformServerState()) {
    notificationID = Random().nextInt(1000000);
    connection.bloc = this;
    on<SelectDirectoryClicked>((event, emit) async {
      String? path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        _runFtpServer(path);
        Map data = _dirToMap(path, Directory(path));
        connection.sendDirectoryData(data);
        emit(state.copyWith(path: path));
      }
    });
    on<TransformData>((event, emit) async {
      emit(
        state.copyWith(
            files: event.files.map((e) => FileModel.fromMap(e)).toList(),
            totalLength: _calcLength(event.files),
            sending: true,
            totalReceived: 0),
      );
      do {
        emit(state.copyWith(speedPerSecond: state.speed, speed: 0));
        NotificationsManager.show(
            notificationID,
            'Connected to ${connection.name}',
            '${state.files[currentIndex].path} | ${state.speedInSecond}',
            state.files[currentIndex].progress.toInt());
        await Future.delayed(const Duration(seconds: 1));
      } while (state.sending);
      NotificationsManager.closeAll();
    });

    on<ProgressChange>((event, emit) {
      List files = state.files.toList();
      files[event.data['index']!] = FileModel.fromMap(event.data);
      currentIndex = event.data['index']!;
      num totalReceived = 0;
      for (var item in files) {
        totalReceived += item.totalReceived;
      }
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
    await ftpServer?.stop();
    NotificationsManager.closeAll();
    if (state.connected) {
      await connection.close();
    }
    return await super.close();
  }
}
