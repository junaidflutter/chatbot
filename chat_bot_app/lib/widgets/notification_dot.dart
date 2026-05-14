import 'package:flutter/material.dart';

class NotificationDot extends StatelessWidget {
  final bool isVisible;
  final double size;
  final Color color;

  const NotificationDot({
    super.key,
    required this.isVisible,
    this.size = 10.0,
    this.color = const Color(0xFFFF8128),
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
