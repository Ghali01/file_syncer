import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
//check if the app has the required permissions to access the device storage
// if not request id
  Future<bool> checkStoragePerm() async {
    if (Platform.isWindows) {
      //windows platform doesn't require any permission
      return true;
    } else {
      DeviceInfoPlugin info = DeviceInfoPlugin();
      var data = await info.androidInfo;
      AndroidBuildVersion version = data.version;
      // for android 10 and prior
      if (version.sdkInt <= 29) {
        var req = await Permission.storage.request();
        return req.isGranted;
      } else {
        var req = await Permission.manageExternalStorage.request();
        return req.isGranted;
      }
    }
  }
}
