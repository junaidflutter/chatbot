import 'package:chat_bot_app/model/app_models.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  final Message message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isUser = message.role == 'user' || !message.isFromAdmin;
    final bgColor = isUser ? const Color(0xFF5B5BEA) : const Color(0xFFF8FAFC);
    final fgColor = isUser ? Colors.white : const Color(0xFF111827);
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final maxWidth = width * 0.78;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth.clamp(220, 360)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              border: isUser ? null : Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: fgColor.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SourcePill(
                      text: isUser
                          ? 'You'
                          : (message.fromDocument ? 'From document' : 'From AI'),
                      foregroundColor: fgColor,
                      backgroundColor: isUser
                          ? Colors.white24
                          : const Color(0xFFE5E7EB),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    final value = dt ?? DateTime.now();
    final hour24 = value.hour;
    final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = hour24 < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class _SourcePill extends StatelessWidget {
  final String text;
  final Color foregroundColor;
  final Color backgroundColor;

  const _SourcePill({
    required this.text,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foregroundColor.withValues(alpha: 0.75),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
