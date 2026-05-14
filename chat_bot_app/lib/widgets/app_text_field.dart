import 'package:chat_bot_app/gen/assets.gen.dart';
import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:chat_bot_app/utils/helper_functions.dart';
import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final bool isInstagramField;
  final String hintText;
  final String? labelText;
  final String? errorText;
  final TextStyle? textStyle;
  final int? maxLine;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool? enable;
  final bool isPassword;
  final int? minLines;
  final int? maxLines;
  final Function()? onTap;
  final ValueChanged<String>? onChanged;
  final bool isGreyLabel;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final Color? borderColor;
  final bool borderless;
  final bool compact;

  const AppTextField({
    super.key,
    this.maxLine,
    this.onTap,
    required this.hintText,
    this.prefixIcon,
    this.isInstagramField = false,
    this.textStyle,
    this.keyboardType,
    this.suffixIcon,
    this.controller,
    this.enable,
    this.minLines,
    this.maxLines,
    this.labelText,
    this.isPassword = false,
    this.validator,
    this.errorText,
    this.onChanged,
    this.isGreyLabel = false,
    this.focusNode,
    this.contentPadding,
    this.borderColor,
    this.borderless = false,
    this.compact = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  void _changeTextVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.borderColor ?? ColorName.borderGrey;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.compact ? 0 : 15),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller ?? TextEditingController(),
        builder: (context, value, child) {
          return TextFormField(
            focusNode: widget.focusNode,
            onTap: widget.onTap,
            onTapOutside: (_) => hideKeyBoard(),
            onChanged: widget.onChanged,
            enabled: widget.enable ?? true,
            controller: widget.controller,
            validator: widget.validator,

            /// FIX: password fields must be single line
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            minLines: widget.isPassword ? 1 : widget.minLines,

            obscureText: widget.isPassword && _obscureText,

            keyboardType: widget.isPassword
                ? TextInputType.visiblePassword
                : widget.keyboardType,

            autofillHints: widget.isPassword
                ? const [AutofillHints.newPassword, AutofillHints.password]
                : const [AutofillHints.username],

            style:
                widget.textStyle ??
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 18,
                  color: ColorName.primaryColor,
                ),

            decoration: InputDecoration(
              isDense: widget.compact,
              contentPadding: (widget.contentPadding ??
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12))
                  .add(EdgeInsets.zero),

              prefixIcon: widget.prefixIcon,
              errorText: widget.errorText,

              suffixIcon: widget.isPassword
                  ? PasswordVisibilityIcon(
                      obscureText: _obscureText,
                      onTap: _changeTextVisibility,
                    )
                  : widget.suffixIcon,

              hintText: widget.hintText,
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: widget.borderless
                    ? BorderSide.none
                    : const BorderSide(
                        color: ColorName.borderGrey,
                        width: 1.0,
                      ),
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: widget.borderless
                    ? BorderSide.none
                    : const BorderSide(
                        color: ColorName.borderGrey,
                        width: 1.0,
                      ),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: widget.borderless
                    ? BorderSide.none
                    : BorderSide(
                        color: borderColor,
                        width: 1.0,
                      ),
              ),

              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: widget.borderless
                    ? BorderSide.none
                    : const BorderSide(color: Colors.red, width: 1.0),
              ),

              filled: true,
              fillColor: Colors.white,
            ),
          );
        },
      ),
    );
  }
}

class PasswordVisibilityIcon extends StatelessWidget {
  final bool obscureText;
  final VoidCallback onTap;

  const PasswordVisibilityIcon({
    super.key,
    required this.obscureText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: obscureText
            ? Assets.icons.eyeClose.svg()
            : Assets.icons.eye.svg(),
      ),
    );
  }
}
