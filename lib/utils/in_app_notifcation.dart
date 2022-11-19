import 'dart:math';

import 'package:files_syncer/utils/colors.dart';
import 'package:flutter/material.dart';

void showInAppNotification(BuildContext context, String message) {
  OverlayState overlayState = Overlay.of(context)!;
  OverlayEntry entry = OverlayEntry(
      builder: (_) => InAppNotification(
            message: message,
          ));
  overlayState.insert(entry);
  Future.delayed(const Duration(seconds: 3)).then((value) => entry.remove());
}

class InAppNotification extends StatefulWidget {
  final String message;
  const InAppNotification({super.key, required this.message});

  @override
  State<InAppNotification> createState() => _InAppNotificationState();
}

class _InAppNotificationState extends State<InAppNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation _transfromTween, _rotateTween;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _transfromTween =
        Tween<double>(begin: 50, end: 0).animate(_animationController);
    _rotateTween =
        Tween<double>(begin: 40, end: 0).animate(_animationController);

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.directional(
      textDirection: TextDirection.ltr,
      bottom: 24,
      start: 16,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => Transform(
            alignment: AlignmentDirectional.topStart,
            transform: Matrix4.translationValues(0, _transfromTween.value, 0)
              ..rotateZ((_rotateTween.value) * pi / 180),
            child: child!),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.hunterGreen, width: 1.7),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            widget.message,
            style: const TextStyle(
                fontSize: 20,
                decoration: TextDecoration.none,
                color: AppColors.keppel),
          ),
        ),
      ),
    );
  }
}
