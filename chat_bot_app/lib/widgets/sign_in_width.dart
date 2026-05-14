import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class SignInWithDivider extends StatelessWidget {
  const SignInWithDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(color: ColorName.borderGrey, width: 50, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            "OR",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: ColorName.darkGrey,
            ),
          ),
        ),
        Container(color: ColorName.borderGrey, width: 50, height: 1),
      ],
    );
  }
}
