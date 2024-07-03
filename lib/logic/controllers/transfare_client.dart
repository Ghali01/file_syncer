import 'dart:io';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:files_syncer/utils/notifications.dart';
import 'package:files_syncer/utils/permissions.dart';

import 'package:files_syncer/logic/models/file_model.dart';
import 'package:files_syncer/logic/models/transfare_client.dart';
import 'package:files_syncer/network/tcp/client.dart';
import 'package:pure_ftp/pure_ftp.dart';

abstract class _BaseTransferClientEvent {}

// the sender was disconnected
class ServerDisconnected extends _BaseTransferClientEvent {}

// the sender select directory
class DirectorySelected extends _BaseTransferClientEvent {
  // the directory tree
  Map data;
  DirectorySelected({
    required this.data,
  });
}

// when file progress is changed
class _ChangeFileProgress extends _BaseTransferClientEvent {
  double progress;
  int index;
  int totalReceived;
  _ChangeFileProgress({
    required this.progress,
    required this.index,
    required this.totalReceived,
  });
}

class TransferClientBloc
    extends Bloc<_BaseTransferClientEvent, TransferClientState> {
  ClientConnectionClient connection;
  late int
      notificationID; // the id is used  to display the progress notification
  int currentIndex =
      0; // the index of the file that currently is being received
  bool connected =
      true; // this bool will assigned to false on disconnect to remove the notification
  TransferClientBloc(this.connection) : super(TransferClientState()) {
    connection.bloc = this;
    notificationID = Random().nextInt(1000000);
    on<DirectorySelected>((event, emit) async {
      bool prmStatus = await AppPermissions()
          .checkStoragePerm(); //check on storage permissions
      print("perm $prmStatus");
      if (prmStatus) {
        String? path = await FilePicker.platform.getDirectoryPath();
        if (path != null) {
          // get the files that need to be sent and send it to the sender
          List<Map<String, dynamic>> files = _compareFiles(path, event.data);
          connection.sendTransferData(files);
          emit(
            state.copyWith(
              path: path,
              files: files.map((e) => FileModel.fromMap(e)).toList(),
              totalLength: _calcLength(files),
              sending: true,
              totalReceived: 0,
            ),
          );
          // start file downloading
          _getFiles(path, files.map((e) => e['path']).toList())
              .then((value) => null);

          // display the speed and the progress notification every 1 second
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
                state.progressValue.toInt());
            await Future.delayed(const Duration(seconds: 1));
          } while (state.sending && connected);
          NotificationsManager.closeAll();
        }
      }
    });

    on<_ChangeFileProgress>((event, emit) {
      // change the state
      List files = state.files.toList();
      files[event.index].progress = event.progress;
      files[event.index].totalReceived = event.totalReceived;
      currentIndex = event.index;
      // calculate the the total size of received files

      num totalReceived = 0;
      for (var item in files) {
        totalReceived += item.totalReceived;
      }
      // send the progress to the sender
      Map data = files[event.index].toMap()..addAll({'index': event.index});
      connection.sendProgressChange(data);
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
    on<ServerDisconnected>((event, emit) =>
        emit(state.copyWith(connected: false, sending: false)));
  }

  ///[rootPath] is the selected dir from the receiver and here used to check if file exists
  List<Map<String, dynamic>> _compareFiles(String rootPath, Map dirData) {
    List<Map<String, dynamic>> files = [];
    for (var item in dirData['subs']) {
      if (item['type'] == 'dir') {
        Directory dir = Directory(rootPath + item['path']);
        if (!dir.existsSync()) {
          // if the directory does't exists create it
          dir.createSync();
        }
        // scan the sup directory
        files.addAll(_compareFiles(rootPath, item));
      }
      if (item['type'] == 'file') {
        item['progress'] = 0;
        item['totalReceived'] = 0;
        File file = File(rootPath + item['path']);
        if (!file.existsSync()) {
          files.add(item);
        } else if (file.lengthSync() != item['length']) {
          // if the file exists but not in the same size delete and add it to re-download
          file.deleteSync();
          files.add(item);
        }
      }
    }
    return files;
  }

// download the files
  ///[rootPath] is the selected dir from the receiver and here used to refer to the files
  Future<void> _getFiles(String rootPath, List files) async {
    final client = FtpClient(
      socketInitOptions: FtpSocketInitOptions(
        host: '192.168.1.7',
        port: 21401,
      ),
      authOptions: FtpAuthOptions(
        username: 'user',
        password: '1234',
      ),
      logCallback: print,
    );
    await client.connect();

    print('connected');
    int index = 0;
    for (String path in files) {
      final remoteFile = client.getFile(path);
      final totalSize = await remoteFile.size();
      int received = 0;
      final file = File(rootPath + path);
      final fi = file.openWrite();

      await for (final chunk in client.fs.downloadFileStream(remoteFile)) {
        received += chunk.length;
        fi.add(chunk);
        add(_ChangeFileProgress(
            progress: received / totalSize * 100,
            index: index,
            totalReceived: received));
      }
      fi.close();
      index++;
    }

    await client.disconnect();
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
    connected = false;
    NotificationsManager.closeAll();
    if (state.connected) {
      await connection.close();
    }
    return await super.close();
  }
}
