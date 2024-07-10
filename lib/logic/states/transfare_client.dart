import 'package:files_syncer/logic/states/transfare_base.dart';

class TransferClientState extends TransferBaseState {
  TransferClientState({
    super.path,
    super.speed,
    super.sending,
    super.speedPerSecond,
    super.connected,
    super.files = const [],
    super.totalLength,
    super.totalReceived = 0,
  });

  TransferClientState copyWith({
    String? path,
    bool? connected,
    bool? sending,
    List? files,
    int? totalLength,
    int? speedPerSecond,
    int? speed,
    int? totalReceived,
  }) {
    return TransferClientState(
      path: path ?? this.path,
      files: files ?? this.files,
      speed: speed ?? this.speed,
      totalLength: totalLength ?? this.totalLength,
      sending: sending ?? this.sending,
      totalReceived: totalReceived ?? this.totalReceived,
      speedPerSecond: speedPerSecond ?? this.speedPerSecond,
      connected: connected ?? this.connected,
    );
  }
}
