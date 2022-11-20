import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsManager {
  static void init() {
    if (Platform.isAndroid) {
      InitializationSettings settings = const InitializationSettings(
          android: AndroidInitializationSettings('logo'));
      FlutterLocalNotificationsPlugin().initialize(settings);
    }
  }

  static void show(int id, String title, String body, int progress) {
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
    }
  }

  static void closeAll() async {
    if (Platform.isAndroid) {
      await FlutterLocalNotificationsPlugin().cancelAll();
    }
  }
}
