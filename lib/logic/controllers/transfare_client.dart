import 'dart:io';
import 'dart:math';
import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:files_syncer/network/tcp/client_listener.dart';
import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:files_syncer/logic/models/transfer_task.dart';
import 'package:files_syncer/utils/notifications.dart';
import 'package:files_syncer/utils/permissions.dart';

import 'package:files_syncer/logic/models/file_model.dart';
import 'package:files_syncer/logic/states/transfare_client.dart';
import 'package:files_syncer/network/tcp/client.dart';
import 'package:pure_ftp/pure_ftp.dart';

class TransferClientBloc extends Cubit<TransferClientState>
    implements IClientListener {
  ClientConnectionClient connection;
  final int notificationID = Random()
      .nextInt(1000000); // the id is used  to display the progress notification
  int currentIndex =
      0; // the index of the file that currently is being received
  bool connected =
      true; // this bool will assigned to false on disconnect to remove the notification

  final List<TransferTask> transferTasks = [];

  TransferClientBloc(this.connection) : super(TransferClientState()) {
    connection.listener = this;
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
  Future<void> _getFiles(TransferTask task) async {
    FtpClient client = FtpClient(
      socketInitOptions: FtpSocketInitOptions(
        host: connection.address,
        port: task.ftpPort,
      ),
      authOptions: const FtpAuthOptions(
        username: 'user',
        password: '1234',
      ),
      logCallback: print,
    );
    await client.connect();

    print('connected');
    final paths = task.files
        .map(
          (e) => e.path,
        )
        .toList();
    for (int i = 0; i < paths.length;) {
      String path = paths[i];
      final remoteFile = client.getFile(path);
      final totalSize = await remoteFile.size();
      int received = 0;
      File file;
      if (task.path != null) {
        file = File(task.path! + path);
      } else {
        file = await _getDownloadFile(path);
      }
      try {
        final fi = file.openWrite();

        await for (final chunk in client.fs.downloadFileStream(remoteFile)) {
          received += chunk.length;
          fi.add(chunk);
          _updateProgress(received / totalSize * 100, received);
        }
        fi.close();
      } catch (_) {
        print('download retried');
        client = client.clone();
        await client.connect();
        continue;
      }
      currentIndex++;
      i++;
    }

    await client.disconnect();
    if (transferTasks.isNotEmpty) {
      final nextTask = transferTasks.removeLast();
      _getFiles(nextTask);
    }
  }

  Future<File> _getDownloadFile(String name) async {
    var file = File('${(await getDownloadDirectory()).absolute.path}/$name');
    int i = 1;
    String newName = '';
    final l = name.split('.');
    while (file.existsSync()) {
      newName = '${l[0]} - $i.${l[1]}';

      file = file =
          File('${(await getDownloadDirectory()).absolute.path}/$newName');
      i++;
    }
    return file;
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

  Future<void> _displayProgress() async {
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

  @override
  void onDirectorySelected(Map data) async {
    bool prmStatus = await AppPermissions()
        .checkStoragePerm(); //check on storage permissions

    if (prmStatus) {
      String? path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        // get the files that need to be sent and send it to the sender
        List<Map<String, dynamic>> files = _compareFiles(path, data);
        connection.sendTransferData(files);

        emit(
          state.copyWith(
            path: path,
            files: [
              ...state.files,
              ...files.map((e) => FileModel.fromMap(e)).toList()
            ],
            totalLength: (state.totalLength ?? 0) + _calcLength(files),
          ),
        );
        final task = TransferTask(
            path: path,
            ftpPort: data['port'],
            files: files.map((e) => FileModel.fromMap(e)).toList());
        if (!state.sending) {
          // start file downloading
          _getFiles(task).then((value) => null);
          _displayProgress();
          emit(state.copyWith(sending: true));
        } else {
          transferTasks.insert(0, task);
        }
      }
    }
  }

  @override
  void onServerDisconnected() {
    emit(state.copyWith(connected: false, sending: false));
  }

  void _updateProgress(double progress, int total) async {
    // change the state
    List files = state.files.toList();
    files[currentIndex].progress = progress;
    files[currentIndex].totalReceived = total;
    // calculate the the total size of received files

    num totalReceived = 0;
    for (var item in files) {
      totalReceived += item.totalReceived;
    }
    // send the progress to the sender
    Map data = files[currentIndex].toMap()..addAll({'index': currentIndex});
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
  }

  @override
  void onShareFile(Map data) async {
    bool prmStatus = await AppPermissions()
        .checkStoragePerm(); //check on storage permissions

    if (prmStatus) {
      final FileModel fileModel = FileModel(
          path: data['name'],
          length: data['length'],
          progress: 0,
          totalReceived: 0);
      emit(
        state.copyWith(
          files: [
            ...state.files,
            fileModel,
          ],
          totalLength: (state.totalLength ?? 0) + fileModel.length,
        ),
      );
      final task = TransferTask(ftpPort: data['port'], files: [fileModel]);
      if (!state.sending) {
        // start file downloading
        _getFiles(task).then((value) => null);
        _displayProgress();
        emit(state.copyWith(sending: true));
      } else {
        transferTasks.insert(0, task);
      }
    }
  }
}
