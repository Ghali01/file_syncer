import 'package:files_syncer/logic/models/file_model.dart';

class TransferTask {
  final String? path;
  final int ftpPort;
  final List<FileModel> files;

  TransferTask({this.path, required this.ftpPort, required this.files});
}
