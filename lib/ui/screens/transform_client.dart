import 'dart:io';

import 'package:files_syncer/logic/controllers/transform_client.dart';
import 'package:files_syncer/logic/models/transform_client.dart';
import 'package:files_syncer/ui/widgets/file_item.dart';
import 'package:files_syncer/ui/widgets/title_bar.dart';
import 'package:files_syncer/ui/widgets/yes_no_dialog.dart';
import 'package:files_syncer/utils/colors.dart';
import 'package:files_syncer/utils/in_app_notifcation.dart';
import 'package:flutter/material.dart';

import 'package:files_syncer/network/tcp/client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransformClientPageArgs {
  ClientConnectionClient connection;
  TransformClientPageArgs({
    required this.connection,
  });
}

class TransformClientPage extends StatelessWidget {
  final TransformClientPageArgs args;
  const TransformClientPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => TransformClientBloc(args.connection),
      child: WillPopScope(
        onWillPop: () async =>
            (await showDialog(
                context: context,
                builder: (_) => const YesNoDialog(
                    title: 'Close Connection',
                    text: 'Do you want to close the connection?'))) ??
            false,
        child: Scaffold(
          appBar: Platform.isWindows
              ? PreferredSize(
                  preferredSize: const Size(double.infinity, 40),
                  child: AppTitleBarr(
                    title: 'connected to ${args.connection.name}',
                  ),
                )
              : AppBar(
                  title: Text('connected to ${args.connection.name}'),
                ),
          body: BlocListener<TransformClientBloc, TransformClientState>(
            listenWhen: (previous, current) => current.connected == false,
            listener: (context, state) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              showInAppNotification(context, "Connection Lost");
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    args.connection.name,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  BlocSelector<TransformClientBloc, TransformClientState,
                      String?>(
                    selector: (state) {
                      return state.path;
                    },
                    builder: (context, state) {
                      return Text(
                        state ?? '',
                        style: const TextStyle(fontSize: 22),
                      );
                    },
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 42,
                      child: Stack(
                        children: [
                          BlocSelector<TransformClientBloc,
                              TransformClientState, double>(
                            selector: (state) {
                              return state.progressValue;
                            },
                            builder: (context, state) {
                              return LayoutBuilder(
                                  builder: (_, box) => Container(
                                        height: box.maxHeight,
                                        width: state * box.maxWidth / 100,
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.keppel.withOpacity(.4),
                                        ),
                                      ));
                            },
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      BlocSelector<TransformClientBloc,
                                          TransformClientState, String>(
                                        selector: (state) {
                                          return state.progress;
                                        },
                                        builder: (context, state) {
                                          return Text(
                                            state,
                                            style:
                                                const TextStyle(fontSize: 22),
                                          );
                                        },
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      BlocSelector<TransformClientBloc,
                                          TransformClientState, String>(
                                        selector: (state) {
                                          return state.speedInSecond;
                                        },
                                        builder: (context, state) {
                                          return Text(
                                            state,
                                            style:
                                                const TextStyle(fontSize: 20),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                BlocSelector<TransformClientBloc,
                                    TransformClientState, String>(
                                  selector: (state) {
                                    return state.totalSize;
                                  },
                                  builder: (context, state) {
                                    return Text(
                                      state,
                                      style: const TextStyle(fontSize: 20),
                                    );
                                  },
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: BlocSelector<TransformClientBloc,
                        TransformClientState, List>(
                      selector: (state) => state.files,
                      builder: (context, state) {
                        return ListView.builder(
                          itemCount: state.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: FileItem(data: state[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
