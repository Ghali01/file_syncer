import 'dart:io';

import 'package:files_syncer/utils/colors.dart';
import 'package:files_syncer/utils/notifications.dart';
import 'package:files_syncer/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dependcy_injection.dart' as di;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  di.init();
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
        splashColor: Colors.amber.shade200.withOpacity(.35),
        colorScheme: ColorScheme.light(
            secondary: Colors.amber.shade200.withOpacity(.35)),
        appBarTheme: AppBarTheme(
            backgroundColor: Colors.amber.shade200,
            foregroundColor: AppColors.hunterGreen),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              backgroundColor: const MaterialStatePropertyAll(AppColors.keppel),
              foregroundColor:
                  const MaterialStatePropertyAll(AppColors.areoBlue),
              alignment: Alignment.center,
              overlayColor: MaterialStatePropertyAll(
                  Colors.amber.shade200.withOpacity(.35))),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            overlayColor: MaterialStatePropertyAll(
                Colors.amber.shade200.withOpacity(.35)),
            foregroundColor: const MaterialStatePropertyAll(AppColors.keppel),
          ),
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: AppColors.hunterGreen),
      ),
    );
  }
}
