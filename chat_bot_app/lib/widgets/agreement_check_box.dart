import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AgreementCheckbox extends StatefulWidget {
  final String actionText; // e.g., "Sign Up" or "Login"
  final ValueChanged<bool> onCheckedChanged; // return checkbox state
  final VoidCallback? onAgreementTap; // called when user taps agreement text

  const AgreementCheckbox({
    super.key,
    required this.actionText,
    required this.onCheckedChanged,
    this.onAgreementTap,
  });

  @override
  State<AgreementCheckbox> createState() => _AgreementCheckboxState();
}

class _AgreementCheckboxState extends State<AgreementCheckbox> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: isChecked,
          onChanged: (value) {
            setState(() {
              isChecked = value ?? false;
              widget.onCheckedChanged(isChecked);
            });
          },
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 14),
              children: [
                const TextSpan(
                  text: 'I have read this ',
                  style: TextStyle(color: ColorName.textGrey),
                ),
                TextSpan(
                  text: 'User Agreement & Privacy Policy',
                  style: const TextStyle(
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = widget.onAgreementTap,
                ),
                TextSpan(
                  text: ' to proceed with ${widget.actionText}.',
                  style: TextStyle(color: ColorName.textGrey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
