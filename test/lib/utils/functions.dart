import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceName() async {
  DeviceInfoPlugin plugin = DeviceInfoPlugin();
  String name = '';
  if (Platform.isAndroid) {
    AndroidDeviceInfo info = await plugin.androidInfo;
    name = info.model;
  } else if (Platform.isWindows) {
    WindowsDeviceInfo info = await plugin.windowsInfo;
    name = info.computerName;
  }
  return name;
}

String lengthToSize(int length) {
  if (length > 1073741824) {
    double size = length / (1073741824);

    return '${size.toStringAsFixed(2)} GB';
  }
  if (length > 1048576) {
    double size = length / (1048576);

    return '${size.toStringAsFixed(2)} MB';
  }
  if (length > 1024) {
    double size = length / (1024);

    return '${size.toStringAsFixed(2)} KB';
  } else {
    return '$length B';
  }
}
