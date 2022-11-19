import 'dart:io';

import 'package:files_syncer/utils/colors.dart';
import 'package:files_syncer/utils/notifications.dart';
import 'package:files_syncer/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    doWhenWindowReady(() {
      appWindow.title = 'File Syncer';

      appWindow.show();
    });
  }
  if (Platform.isAndroid) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  NotificationsManager.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.home,
      onGenerateRoute: Routes.generate,
      theme: ThemeData(
        primaryColor: Colors.amber.shade200,
        appBarTheme: AppBarTheme(
            backgroundColor: Colors.amber.shade200,
            foregroundColor: AppColors.hunterGreen),
        elevatedButtonTheme: const ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(AppColors.keppel),
            foregroundColor: MaterialStatePropertyAll(AppColors.areoBlue),
            alignment: Alignment.center,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStatePropertyAll(AppColors.keppel),
          ),
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: AppColors.hunterGreen),
      ),
    );
  }
}
