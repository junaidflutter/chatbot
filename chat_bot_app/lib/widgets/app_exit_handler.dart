import 'package:chat_bot_app/utils/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppExitHandler extends StatelessWidget {
  final Widget child;

  const AppExitHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await showExitDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
