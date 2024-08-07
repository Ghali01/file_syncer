import 'package:files_syncer/logic/states/transfare_base.dart';

class TransferServerState extends TransferBaseState {
  TransferServerState({
    super.path,
    super.speed,
    super.speedPerSecond,
    super.connected,
    super.sending,
    super.files = const [],
    super.totalLength,
    super.totalReceived = 0,
  });

  TransferServerState copyWith({
    String? path,
    List? files,
    bool? connected,
    bool? sending,
    int? totalLength,
    int? speedPerSecond,
    int? speed,
    int? totalReceived,
  }) {
    return TransferServerState(
      path: path ?? this.path,
      speed: speed ?? this.speed,
      files: files ?? this.files,
      totalLength: totalLength ?? this.totalLength,
      totalReceived: totalReceived ?? this.totalReceived,
      sending: sending ?? this.sending,
      speedPerSecond: speedPerSecond ?? this.speedPerSecond,
      connected: connected ?? this.connected,
    );
  }
}
