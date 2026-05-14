import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.onTap,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: Size(double.infinity, height ?? 50),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            ...(icon == null ? const <Widget>[] : <Widget>[icon!]),
            if (icon != null) const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: TextStyle(fontSize: 16, color: textColor),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OutlineAppButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const OutlineAppButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 45),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        side: const BorderSide(color: ColorName.primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1A161E),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}
