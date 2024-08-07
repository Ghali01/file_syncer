import 'dart:io';

import 'package:files_syncer/logic/controllers/transfare_server.dart';
import 'package:files_syncer/logic/states/transfare_server.dart';
import 'package:files_syncer/ui/widgets/file_item.dart';
import 'package:files_syncer/ui/widgets/title_bar.dart';
import 'package:files_syncer/ui/widgets/yes_no_dialog.dart';
import 'package:files_syncer/utils/colors.dart';
import 'package:files_syncer/utils/in_app_notifcation.dart';
import 'package:flutter/material.dart';

import 'package:files_syncer/network/tcp/server.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferServerPageArgs {
  ClientConnectionServer connection;
  TransferServerPageArgs({
    required this.connection,
  });
}

class TransferServerPage extends StatelessWidget {
  final TransferServerPageArgs args;
  const TransferServerPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => TransferServerBloc(args.connection),
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
          body: BlocListener<TransferServerBloc, TransferServerState>(
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
                  Builder(builder: (context) {
                    return Row(
                      children: [
                        ElevatedButton(
                          child: const Text('Sync Folder'),
                          onPressed: () {
                            context
                                .read<TransferServerBloc>()
                                .selectDirectory();
                          },
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        ElevatedButton(
                          child: const Text('Share File'),
                          onPressed: () {
                            context.read<TransferServerBloc>().selectFiles();
                          },
                        ),
                      ],
                    );
                  }),
                  BlocSelector<TransferServerBloc, TransferServerState,
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
                          BlocSelector<TransferServerBloc, TransferServerState,
                              double>(
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
                                      BlocSelector<TransferServerBloc,
                                          TransferServerState, String>(
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
                                      BlocSelector<TransferServerBloc,
                                          TransferServerState, String>(
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
                                BlocSelector<TransferServerBloc,
                                    TransferServerState, String>(
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
                    child: BlocSelector<TransferServerBloc, TransferServerState,
                        List>(
                      selector: (state) => state.files,
                      builder: (context, state) {
                        return ListView.builder(
                          itemCount: state.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
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
