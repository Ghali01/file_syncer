import 'package:files_syncer/utils/functions.dart';

abstract class TransformBaseState {
  String? path;
  List files;
  int? totalLength;
  int totalReceived;
  bool connected;
  int? speed;
  int? speedPerSecond;
  bool sending;
  TransformBaseState({
    this.path,
    this.speed,
    this.speedPerSecond,
    this.sending = false,
    this.connected = true,
    this.files = const [],
    this.totalLength,
    this.totalReceived = 0,
  });

  String get totalSize =>
      totalLength != null ? lengthToSize(totalLength ?? 0) : '';
  String get progress {
    if (totalLength != null) {
      if (totalLength == 0) {
        return '100%';
      } else {
        return '${(totalReceived * 100 / totalLength!).toStringAsFixed(2)}%';
      }
    } else {
      return '';
    }
  }

  double get progressValue {
    if (totalLength != null) {
      if (totalLength == 0) {
        return 100;
      } else {
        return (totalReceived * 100 / totalLength!);
      }
    } else {
      return 0;
    }
  }

  String get speedInSecond => speedPerSecond != null && sending
      ? '${lengthToSize(speedPerSecond!)}/s'
      : '';
}
