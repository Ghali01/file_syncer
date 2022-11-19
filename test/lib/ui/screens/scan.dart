import 'dart:io';

import 'package:files_syncer/logic/controllers/scan.dart';
import 'package:files_syncer/logic/models/scan.dart';
import 'package:files_syncer/ui/screens/transform_client.dart';
import 'package:files_syncer/ui/widgets/title_bar.dart';
import 'package:files_syncer/utils/colors.dart';
import 'package:files_syncer/utils/in_app_notifcation.dart';
import 'package:files_syncer/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScanCubit(),
      child: Scaffold(
        appBar: Platform.isWindows
            ? const PreferredSize(
                preferredSize: Size(double.infinity, 40),
                child: AppTitleBarr(
                  title: 'File Syncer',
                ),
              )
            : AppBar(),
        body: BlocListener<ScanCubit, ScanState>(
          listenWhen: (previous, current) =>
              previous.connecting == true && current.connecting == false,
          listener: (context, state) {
            if (state.connected) {
              Navigator.of(context).pushReplacementNamed(Routes.transformClient,
                  arguments:
                      TransformClientPageArgs(connection: state.connection!));
            } else {
              showInAppNotification(context, 'Connection Rejected');
            }
          },
          child: BlocBuilder<ScanCubit, ScanState>(
            buildWhen: (previous, current) =>
                previous.scanning != current.scanning ||
                current.connecting != previous.connecting,
            builder: (context, state) {
              if (state.scanning) {
                return Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(
                        height: 16,
                      ),
                      Text(
                        'Scanning',
                        style: TextStyle(fontSize: 21),
                      ),
                    ],
                  ),
                );
              }
              if (state.connecting) {
                return Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        'Connecting To ${state.connectTo}.',
                        style: const TextStyle(fontSize: 21),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: state.devices.isEmpty
                        ? const Center(
                            child: Text(
                              'No Devices Found',
                              style: TextStyle(fontSize: 28),
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.devices.length,
                            itemBuilder: (context, index) => InkWell(
                              onTap: () =>
                                  context.read<ScanCubit>().connect(index),
                              child: ListTile(
                                  leading: Text(state.devices[index].name)),
                            ),
                          ),
                  ),
                  IconButton(
                      onPressed: () => context
                          .read<ScanCubit>()
                          .scan()
                          .then((value) => null),
                      icon: const Icon(
                        Icons.refresh,
                        color: AppColors.hunterGreen,
                        size: 32,
                      ))
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
