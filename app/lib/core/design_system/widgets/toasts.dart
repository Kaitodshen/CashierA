import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// One place for toast styling so every screen reports success and errors the
/// same way.
abstract final class AppToast {
  static void success(BuildContext context, String message) =>
      _show(context, message, ToastificationType.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, ToastificationType.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, ToastificationType.info);

  static void _show(
    BuildContext context,
    String message,
    ToastificationType type,
  ) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flatColored,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 4),
      alignment: Alignment.topCenter,
    );
  }
}
