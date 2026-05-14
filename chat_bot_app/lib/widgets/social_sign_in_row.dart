import 'package:chat_bot_app/gen/assets.gen.dart';
import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class SocialSignInRow extends StatelessWidget {
  const SocialSignInRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _socialTile(Assets.icons.facebookIcon.svg()),
        _socialTile(Assets.icons.googleIcon.svg()),
        _socialTile(Assets.icons.appleIcon.svg()),
      ],
    );
  }

  Widget _socialTile(Widget icon) {
    return Expanded(
      child: Container(
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: ColorName.borderGrey, width: 0.7),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(child: icon),
      ),
    );
  }
}
