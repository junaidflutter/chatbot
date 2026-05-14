import 'package:flutter/material.dart';

class CustomAnimatedText extends StatefulWidget {
  final String text;
  final VoidCallback? onTextUpdate;
  final VoidCallback? onComplete;
  final TextAlign textAlign;
  final Duration charDelay;

  const CustomAnimatedText({
    super.key,
    required this.text,
    this.onTextUpdate,
    this.onComplete,
    this.textAlign = TextAlign.start,
    this.charDelay = const Duration(milliseconds: 45),
  });

  @override
  State<CustomAnimatedText> createState() => _CustomAnimatedTextState();
}

class _CustomAnimatedTextState extends State<CustomAnimatedText> {
  String _visibleText = "";

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  Future<void> _startTyping() async {
    for (int i = 1; i <= widget.text.length; i++) {
      await Future.delayed(widget.charDelay);
      if (!mounted) return;

      setState(() {
        _visibleText = widget.text.substring(0, i);
      });

      widget.onTextUpdate?.call();
    }

    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _visibleText,
      textAlign: widget.textAlign,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
