import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingAnimation extends StatelessWidget {
  final double size;
  const LoadingAnimation({super.key, this.size = 250});

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator.adaptive(strokeWidth: 2));
  }
}

class AiLoadingAnimation extends StatelessWidget {
  final double size;
  const AiLoadingAnimation({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animations/connect.json',
        width: size,
        height: size,
        repeat: true,
      ),
    );
  }
}
