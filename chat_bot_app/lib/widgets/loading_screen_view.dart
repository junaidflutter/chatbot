import 'package:chat_bot_app/widgets/loading_animation.dart';
import 'package:flutter/material.dart';

class LoadingScreenView extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final bool isBackgroundRequired;

  const LoadingScreenView({
    super.key,
    required this.isLoading,
    required this.child,
    this.isBackgroundRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: isBackgroundRequired ? Colors.black54 : Colors.transparent,
            alignment: Alignment.center,
            child: const Center(child: LoadingAnimation()),
          ),
      ],
    );
  }
}
