import 'package:files_syncer/logic/models/transform_base.dart';

class TransformServerState extends TransformBaseState {
  TransformServerState({
    super.path,
    super.speed,
    super.speedPerSecond,
    super.connected,
    super.sending,
    super.files = const [],
    super.totalLength,
    super.totalReceived = 0,
  });

  TransformServerState copyWith({
    String? path,
    List? files,
    bool? connected,
    bool? sending,
    int? totalLength,
    int? speedPerSecond,
    int? speed,
    int? totalReceived,
  }) {
    return TransformServerState(
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
