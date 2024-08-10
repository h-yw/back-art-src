import 'package:flutter/material.dart';

Future<Object?> showTopBottomSheet(BuildContext context,
    {required Widget child, double offset = -1.0}) {
  return showGeneralDialog(
    context: context,
    barrierLabel: MaterialLocalizations.of(context).dialogLabel,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 500),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ).drive(Tween<Offset>(
          begin: Offset(0, offset), // 从屏幕上方开始
          end: Offset.zero,
        )),
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      );
    },
  );
}
