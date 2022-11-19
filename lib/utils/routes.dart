import 'package:files_syncer/ui/screens/home.dart';
import 'package:files_syncer/ui/screens/host.dart';
import 'package:files_syncer/ui/screens/scan.dart';
import 'package:files_syncer/ui/screens/transform_client.dart';
import 'package:files_syncer/ui/screens/transform_server.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Routes {
  static const home = '/';
  static const host = '/host';
  static const scan = '/scan';
  static const transformClient = '/transformClient';
  static const transformServer = '/transformServer';

  static Route? generate(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case host:
        return MaterialPageRoute(builder: (_) => HostPage());
      case scan:
        return MaterialPageRoute(builder: (_) => const ScanPage());
      case transformServer:
        TransformServerPageArgs args =
            settings.arguments as TransformServerPageArgs;
        return MaterialPageRoute(
            builder: (_) => TransformServerPage(
                  args: args,
                ));
      case transformClient:
        TransformClientPageArgs args =
            settings.arguments as TransformClientPageArgs;
        return MaterialPageRoute(
            builder: (_) => TransformClientPage(
                  args: args,
                ));
    }
  }
}
