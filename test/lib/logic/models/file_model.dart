import 'dart:convert';

import 'package:files_syncer/utils/functions.dart';

class FileModel {
  String path;
  int length;
  double progress;
  int totalReceived;
  FileModel({
    required this.path,
    required this.length,
    required this.progress,
    required this.totalReceived,
  });

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'path': path});
    result.addAll({'length': length});
    result.addAll({'progress': progress});
    result.addAll({'totalReceived': totalReceived});

    return result;
  }

  factory FileModel.fromMap(Map<dynamic, dynamic> map) {
    return FileModel(
      path: map['path'] ?? '',
      length: map['length']?.toInt() ?? 0,
      progress: map['progress']?.toDouble() ?? 0.0,
      totalReceived: map['totalReceived']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory FileModel.fromJson(String source) =>
      FileModel.fromMap(json.decode(source));

  String get size => lengthToSize(length);
}
