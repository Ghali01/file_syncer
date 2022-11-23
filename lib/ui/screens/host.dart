import 'dart:io';

import 'package:files_syncer/logic/controllers/host.dart';
import 'package:files_syncer/logic/models/host.dart';
import 'package:files_syncer/network/tcp/server.dart';
import 'package:files_syncer/ui/screens/transfare_server.dart';
import 'package:files_syncer/ui/widgets/title_bar.dart';
import 'package:files_syncer/ui/widgets/yes_no_dialog.dart';
import 'package:files_syncer/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HostPage extends StatelessWidget {
  const HostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => HostBloc(),
      child: Scaffold(
        appBar: Platform.isWindows
            ? const PreferredSize(
                preferredSize: Size(double.infinity, 40),
                child: AppTitleBarr(
                  title: 'File Syncer',
                ),
              )
            : AppBar(),
        body: BlocListener<HostBloc, HostState>(
          listener: (context, state) async {
            if (state.connection != null && !state.connected) {
              // a device try to connect
              ClientConnectionServer connection = state.connection!;
              bool? accept = await showDialog(
                  context: context,
                  builder: (_) => YesNoDialog(
                      title: 'New Connection',
                      text:
                          '${connection.name} try to connect to your device.'));
              if (accept == true) {
                // handshake was accepted
                context
                    .read<HostBloc>()
                    .add(AcceptConnectionEvent(connection: connection));
              } else {
                // handshake was rejected or dialog was canceled
                context
                    .read<HostBloc>()
                    .add(RejectConnectionEvent(connection: connection));
              }
            }
            if (state.connected) {
              // device connected
              Navigator.of(context).pushReplacementNamed(Routes.transformServer,
                  arguments:
                      TransferServerPageArgs(connection: state.connection!));
            }
          },
          child: Center(child: BlocBuilder<HostBloc, HostState>(
            builder: (context, state) {
              return Column(
                children: const [
                  Text(
                    "Waiting connection",
                    style: TextStyle(fontSize: 28),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  CircularProgressIndicator(),
                ],
              );
            },
          )),
        ),
      ),
    );
  }
}
