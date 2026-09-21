import 'package:flutter/material.dart';

void showSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
  bool persist = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: action,
      duration: duration,
      persist: persist,
    ),
  );
}
