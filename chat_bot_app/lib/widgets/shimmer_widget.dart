import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoadingWidget extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoadingWidget({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Shimmer.fromColors(
            baseColor: const Color.fromARGB(255, 34, 34, 35),
            highlightColor: const Color.fromARGB(255, 137, 135, 135),
            child: child,
          )
        : child;
  }
}
