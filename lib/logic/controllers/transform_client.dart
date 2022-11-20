import 'dart:io';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:files_syncer/utils/notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:files_syncer/logic/models/file_model.dart';
import 'package:files_syncer/logic/models/transform_client.dart';
import 'package:files_syncer/network/tcp/client.dart';

abstract class _BaseTransformClientEvent {}

class ServerDisconnected extends _BaseTransformClientEvent {}

class DirectorySelected extends _BaseTransformClientEvent {
  Map data;
  DirectorySelected({
    required this.data,
  });
}

class _ChangeFileProgress extends _BaseTransformClientEvent {
  double progress;
  int index;
  int totalReceived;
  _ChangeFileProgress({
    required this.progress,
    required this.index,
    required this.totalReceived,
  });
}

class TransformClientBloc
    extends Bloc<_BaseTransformClientEvent, TransformClientState> {
  ClientConnectionClient connection;
  late int notificationID;
  int currentIndex = 0;
  TransformClientBloc(this.connection) : super(TransformClientState()) {
    connection.bloc = this;
    notificationID = Random().nextInt(1000000);
    on<DirectorySelected>((event, emit) async {
      bool prmStatus = await _checkPerm();
      if (prmStatus) {
        String? path = await FilePicker.platform.getDirectoryPath();
        if (path != null) {
          List<Map<String, dynamic>> files = _compareFiles(path, event.data);
          connection.sendTransformData(files);
          emit(
            state.copyWith(
                path: path,
                files: files.map((e) => FileModel.fromMap(e)).toList(),
                totalLength: _calcLength(files),
                sending: true,
                totalReceived: 0),
          );

          _getFiles(path, files.map((e) => e['path']).toList())
              .then((value) => null);
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
        }
      }
    });
    on<_ChangeFileProgress>((event, emit) {
      List files = state.files.toList();
      files[event.index].progress = event.progress;
      files[event.index].totalReceived = event.totalReceived;
      currentIndex = event.index;
      num totalReceived = 0;
      for (var item in files) {
        totalReceived += item.totalReceived;
      }
      Map data = files[event.index].toMap()..addAll({'index': event.index});
      connection.sendProgressChange(data);

      num speed = (state.speed ?? 0) + totalReceived - state.totalReceived;
      bool sending = totalReceived == state.totalLength! ? false : true;

      emit(state.copyWith(
          files: files,
          totalReceived: totalReceived.toInt(),
          sending: sending,
          speed: speed.toInt()));
    });
    on<ServerDisconnected>(
        (event, emit) => emit(state.copyWith(connected: false)));
  }

  List<Map<String, dynamic>> _compareFiles(String rootPath, Map dirData) {
    List<Map<String, dynamic>> files = [];
    for (var item in dirData['subs']) {
      if (item['type'] == 'dir') {
        Directory dir = Directory(rootPath + item['path']);
        if (!dir.existsSync()) {
          dir.createSync();
        }
        files.addAll(_compareFiles(rootPath, item));
      }
      if (item['type'] == 'file') {
        item['progress'] = 0;
        item['totalReceived'] = 0;
        File file = File(rootPath + item['path']);
        if (!file.existsSync()) {
          files.add(item);
        } else if (file.lengthSync() != item['length']) {
          file.deleteSync();
          files.add(item);
        }
      }
    }
    return files;
  }

  Future<void> _getFiles(String rootPath, List files) async {
    FTPConnect ftpConnect =
        FTPConnect(connection.address, port: 21401, user: 'user', pass: '1234');
    await ftpConnect.connect();
    int index = 0;
    for (String path in files) {
      await ftpConnect.changeDirectory('/');
      List lp = path.split('/');
      String name = lp.removeLast();
      for (var sig in lp) {
        await ftpConnect.changeDirectory(sig);
      }
      await ftpConnect.downloadFile(
        name,
        File(rootPath + path),
        onProgress: (progress, totalReceived, __) => add(_ChangeFileProgress(
            progress: progress, index: index, totalReceived: totalReceived)),
      );
      index++;
    }
    await ftpConnect.disconnect();
  }

  Future<bool> _checkPerm() async {
    if (Platform.isWindows) {
      return true;
    } else {
      var status = await Permission.storage.isGranted;
      if (!status) {
        var req = await Permission.storage.request();
        if (req.isGranted) {
          return await _checkAllPerm();
        } else {
          return false;
        }
      } else {
        return await _checkAllPerm();
      }
    }
  }

  Future<bool> _checkAllPerm() async {
    DeviceInfoPlugin info = DeviceInfoPlugin();
    var data = await info.androidInfo;
    AndroidBuildVersion version = data.version;
    if (version.sdkInt < 30) {
      return true;
    }

    var status = await Permission.manageExternalStorage.isGranted;
    if (!status) {
      var req = await Permission.manageExternalStorage.request();
      return req.isGranted;
    } else {
      return true;
    }
  }

  int _calcLength(List<Map> files) {
    num sum = 0;
    for (var item in files) {
      sum += item['length']!.toInt();
    }
    return sum.toInt();
  }

  @override
  Future<void> close() async {
    NotificationsManager.closeAll();
    if (state.connected) {
      await connection.close();
    }
    return await super.close();
  }
}
