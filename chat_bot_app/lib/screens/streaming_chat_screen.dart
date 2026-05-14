import 'package:chat_bot_app/bloc/streaming_chat/streaming_chat_cubit.dart';
import 'package:chat_bot_app/bloc/streaming_chat/streaming_chat_state.dart';
import 'package:chat_bot_app/widgets/chat_input_bar.dart';
import 'package:chat_bot_app/widgets/chat_loader.dart';
import 'package:chat_bot_app/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StreamingChatScreen extends StatelessWidget {
  const StreamingChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final surfaceColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final canvasColor = isDark
        ? const Color(0xFF0B1020)
        : const Color(0xFFF5F7FB);

    return BlocProvider(
      create: (_) => StreamingChatCubit()..bootstrap(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Streaming Chat'),
              backgroundColor: canvasColor,
              foregroundColor: textColor,
              elevation: 0,
              actions: [
                IconButton(
                  tooltip: 'New chat',
                  onPressed: () =>
                      context.read<StreamingChatCubit>().startNewChat(),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            backgroundColor: canvasColor,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: BlocBuilder<StreamingChatCubit, StreamingChatState>(
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
                                'Streaming chat will appear here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
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
                              if (message.isLoading &&
                                  state.isAssistantTyping) {
                                return const ChatBubbleLoader();
                              }
                              return ChatMessageBubble(message: message);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  BlocBuilder<StreamingChatCubit, StreamingChatState>(
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
                            isSending:
                                state.status == StreamingChatStatus.sending,
                            onChanged: context
                                .read<StreamingChatCubit>()
                                .onInputChanged,
                            onSend: () => context
                                .read<StreamingChatCubit>()
                                .sendMessage(),
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
