import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class TermsAndPrivacyWidget extends StatelessWidget {
  const TermsAndPrivacyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: ColorName.darkGrey,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            height: 1.75,
          ),
          children: [
            const TextSpan(
              text:
                  "By tapping with Apple, Facebook, Google, you agree with our ",
            ),
            TextSpan(
              text: "Terms Conditions",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
              ),
            ),
            const TextSpan(text: " and "),
            TextSpan(
              text: "Privacy Policy",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
