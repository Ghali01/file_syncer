import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

class NotificationsManager {
  static void init() {
    if (Platform.isAndroid) {
      InitializationSettings settings = const InitializationSettings(
          android: AndroidInitializationSettings('logo'));
      FlutterLocalNotificationsPlugin().initialize(settings);
    }
  }

  static void show(
      int id, String title, String body, int progress, int totalProgress) {
    if (Platform.isAndroid) {
      FlutterLocalNotificationsPlugin().show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails('ch1', 'progress channel',
              channelDescription: "this channel to display the progress",
              maxProgress: 100,
              showProgress: true,
              importance: Importance.low,
              progress: progress),
        ),
      );
    } else if (Platform.isWindows) {
      WindowsTaskbar.setProgressMode(TaskbarProgressMode.indeterminate);
      WindowsTaskbar.setProgress(totalProgress, 100);
    }
  }

  static void closeAll() async {
    if (Platform.isAndroid) {
      await FlutterLocalNotificationsPlugin().cancelAll();
    }
    if (Platform.isWindows) {
      WindowsTaskbar.setProgressMode(TaskbarProgressMode.noProgress);
    }
  }
}
