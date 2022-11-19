import 'package:files_syncer/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class AppTitleBarr extends StatelessWidget {
  final String title;
  const AppTitleBarr({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: MoveWindow(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                      fontSize: 24),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Navigator.of(context).canPop()
                  ? WindowButton(
                      colors: WindowButtonColors(
                        normal: Theme.of(context).appBarTheme.backgroundColor,
                        iconNormal:
                            Theme.of(context).appBarTheme.foregroundColor,
                        iconMouseOver:
                            Theme.of(context).appBarTheme.backgroundColor,
                        mouseOver: AppColors.keppel,
                        iconMouseDown:
                            Theme.of(context).appBarTheme.backgroundColor,
                        mouseDown: AppColors.keppel,
                      ),
                      iconBuilder: (_) => const Icon(
                        Icons.arrow_back,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : const SizedBox(),
              const SizedBox(
                width: 16,
              ),
              MinimizeWindowButton(
                colors: WindowButtonColors(
                  normal: Theme.of(context).appBarTheme.backgroundColor,
                  iconNormal: Theme.of(context).appBarTheme.foregroundColor,
                  iconMouseOver: Theme.of(context).appBarTheme.backgroundColor,
                  mouseOver: AppColors.keppel,
                  iconMouseDown: Theme.of(context).appBarTheme.backgroundColor,
                  mouseDown: AppColors.keppel,
                ),
              ),
              MaximizeWindowButton(
                colors: WindowButtonColors(
                  normal: Theme.of(context).appBarTheme.backgroundColor,
                  iconNormal: Theme.of(context).appBarTheme.foregroundColor,
                  iconMouseOver: Theme.of(context).appBarTheme.backgroundColor,
                  mouseOver: AppColors.keppel,
                  iconMouseDown: Theme.of(context).appBarTheme.backgroundColor,
                  mouseDown: AppColors.keppel,
                ),
              ),
              CloseWindowButton(
                colors: WindowButtonColors(
                  normal: Theme.of(context).appBarTheme.backgroundColor,
                  iconNormal: Theme.of(context).appBarTheme.foregroundColor,
                  iconMouseOver: Theme.of(context).appBarTheme.backgroundColor,
                  mouseOver: AppColors.keppel,
                  iconMouseDown: Theme.of(context).appBarTheme.foregroundColor,
                  mouseDown: Colors.red,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
