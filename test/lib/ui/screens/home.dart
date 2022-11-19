import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:files_syncer/ui/widgets/title_bar.dart';
import 'package:files_syncer/utils/in_app_notifcation.dart';
import 'package:files_syncer/utils/notifications.dart';
import 'package:files_syncer/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key}) {
    _checkPerm().then((value) => null);
  }

  Future<void> _checkPerm() async {
    if (Platform.isWindows) {
      return;
    } else {
      DeviceInfoPlugin info = DeviceInfoPlugin();
      var data = await info.androidInfo;
      AndroidBuildVersion version = data.version;
      if (version.sdkInt >= 33) {
        await (FlutterLocalNotificationsPlugin()
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()!)
            .requestPermission();
      }
      var status = await Permission.storage.isGranted;
      if (!status) {
        var req = await Permission.storage.request();
        if (req.isGranted) {
          await _checkAllPerm();
        }
      } else {
        await _checkAllPerm();
      }
    }
  }

  Future<void> _checkAllPerm() async {
    DeviceInfoPlugin info = DeviceInfoPlugin();
    var data = await info.androidInfo;
    AndroidBuildVersion version = data.version;
    if (version.sdkInt < 30) {
      return;
    }

    var status = await Permission.manageExternalStorage.isGranted;
    if (!status) {
      await Permission.manageExternalStorage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Platform.isWindows
          ? const PreferredSize(
              preferredSize: Size(double.infinity, 40),
              child: AppTitleBarr(
                title: 'File Syncer',
              ),
            )
          : AppBar(
              title: const Text('File Syncer'),
            ),
      body: Center(
        child: SizedBox(
          width: 250,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(Routes.host),
                label: const Text(
                  'Send',
                  style: TextStyle(fontSize: 32),
                ),
                icon: const Icon(
                  Icons.upload,
                  size: 60,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(Routes.scan),
                label: const Text(
                  'Receive',
                  style: TextStyle(fontSize: 32),
                ),
                icon: const Icon(
                  Icons.download,
                  size: 60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
