import 'package:flutter/material.dart';

enum ToastType { success, error, info }

class Toast {
  static void show(BuildContext context, String message, ToastType type) {
    final overlay = Overlay.of(context);
    final snackBarTheme = Theme.of(context).snackBarTheme;

    Color backgroundColor;
    switch (type) {
      case ToastType.success:
        backgroundColor = Colors.green;
        break;
      case ToastType.error:
        backgroundColor = Colors.red;
        break;
      case ToastType.info:
        backgroundColor = Colors.blue;
        break;
    }

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100.0,
        left: MediaQuery.of(context).size.width * 0.1,
        right: MediaQuery.of(context).size.width * 0.1,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Text(
              message,
              style: snackBarTheme.contentTextStyle?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}