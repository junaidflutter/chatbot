import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:chat_bot_app/utils/app_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppDialogs {
  static void showIosDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
    Color confirmTextColor = Colors.red,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ).paddingOnly(top: 10),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: ColorName.grey,
            ),
          ),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: ColorName.green,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              onConfirm();
            },
            isDestructiveAction: true,
            child: Text(
              confirmText,
              style: TextStyle(
                color: confirmTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
