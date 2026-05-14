import 'package:chat_bot_app/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final Future<bool> Function() onSend;
  final bool isSending;
  final bool isEnabled;

  const ChatInputBar({
    super.key,
    required this.onChanged,
    required this.onSend,
    required this.isSending,
    required this.isEnabled,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!widget.isEnabled || widget.isSending) return;
    final sent = await widget.onSend();
    if (sent) {
      _controller.clear();
      widget.onChanged('');
      if (mounted) {
        setState(() {
          _hasText = false;
        });
      }
    }
  }

  Widget _buildSendButton(bool enabled) {
    if (widget.isSending) {
      return const Padding(
        padding: EdgeInsets.only(right: 4),
        child: SizedBox(
          width: 16,
          height: 16,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return Icon(
      Icons.send_rounded,
      size: 20,
      color: enabled ? const Color(0xFF211B2A) : Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: AppTextField(
          controller: _controller,
          focusNode: _focusNode,
          hintText: 'Type a msg',
          keyboardType: TextInputType.text,
          maxLines: 4,
          minLines: 1,
          compact: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          borderColor: const Color(0xFFD9D9D9),
          suffixIcon: InkWell(
            onTap: _hasText && widget.isEnabled && !widget.isSending
                ? _handleSend
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildSendButton(_hasText && widget.isEnabled),
            ),
          ),
          onChanged: (value) {
            widget.onChanged(value);
            final hasText = value.trim().isNotEmpty;
            if (_hasText != hasText) {
              setState(() {
                _hasText = hasText;
              });
            }
          },
        ),
      ),
    );
  }
}
