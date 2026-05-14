import 'package:flutter/material.dart';

class AppBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required Widget child,
    bool isDismissible = false,
    bool enableDrag = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: child,
          ),
        );
      },
    );
  }
}
