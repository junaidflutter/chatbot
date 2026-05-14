import 'package:chat_bot_app/bloc/chat/chat_cubit.dart';
import 'package:chat_bot_app/bloc/chat/chat_state.dart';
import 'package:chat_bot_app/widgets/chat_input_bar.dart';
import 'package:chat_bot_app/widgets/chat_loader.dart';
import 'package:chat_bot_app/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const ChatScreen({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final surfaceColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final canvasColor = isDark ? const Color(0xFF0B1020) : const Color(0xFFF5F7FB);

    return BlocProvider(
      create: (_) => ChatCubit()..bootstrap(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              backgroundColor: canvasColor,
              foregroundColor: textColor,
              elevation: 0,
              actions: [
                IconButton(
                  tooltip: 'New chat',
                  onPressed: () => context.read<ChatCubit>().startNewChat(),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            backgroundColor: canvasColor,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: BlocBuilder<ChatCubit, ChatState>(
                      builder: (context, state) {
                        if (state.messages.isEmpty) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                              ),
                            ),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: borderColor),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final message = state.messages[index];
                              if (message.isLoading && state.isAssistantLoading) {
                                return const ChatBubbleLoader();
                              }
                              return ChatMessageBubble(message: message);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  BlocBuilder<ChatCubit, ChatState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          if (state.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ChatInputBar(
                            isEnabled: state.canSend,
                            isSending: state.status == ChatStatus.sending,
                            onChanged: context.read<ChatCubit>().onInputChanged,
                            onSend: () =>
                                context.read<ChatCubit>().sendMessage(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
