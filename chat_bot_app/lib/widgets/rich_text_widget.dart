import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class AppRichTextWidget extends StatelessWidget {
  final String? dontHaveAccount;
  final String? text;
  final String? lastHiding;
  final String? moreText;
  final VoidCallback? onTap;

  const AppRichTextWidget({
    super.key,
    required this.dontHaveAccount,
    required this.text,
    this.moreText,
    this.lastHiding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: RichText(
          text: TextSpan(
            text: dontHaveAccount,
            style: const TextStyle(color: ColorName.darkGrey, fontSize: 16),
            children: <TextSpan>[
              TextSpan(
                text: text,
                style: const TextStyle(
                  color: ColorName.blue,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
              TextSpan(
                text: moreText,
                style: const TextStyle(
                  color: ColorName.darkGrey,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
              TextSpan(
                text: lastHiding,
                style: const TextStyle(
                  color: ColorName.blue,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
