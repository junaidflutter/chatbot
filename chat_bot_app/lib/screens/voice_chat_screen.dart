import 'package:chat_bot_app/bloc/voice_chat/voice_chat_cubit.dart';
import 'package:chat_bot_app/bloc/voice_chat/voice_chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VoiceChatScreen extends StatelessWidget {
  const VoiceChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VoiceChatCubit(),
      child: const _VoiceChatBody(),
    );
  }
}

class _VoiceChatBody extends StatelessWidget {
  const _VoiceChatBody();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasColor = isDark ? const Color(0xFF0B1020) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: canvasColor,
      appBar: AppBar(
        title: const Text('Voice Chat'),
        backgroundColor: canvasColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<VoiceChatCubit, VoiceChatState>(
          builder: (context, state) {
            final isListening = state is ReceivingVoiceState;
            final isSpeaking = state is SendingVoiceState;
            final error = state is VoiceChatError ? state.error : null;
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulseMic(isActive: isListening),
                          const SizedBox(height: 24),
                          Text(
                            _statusText(state),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 18),
                            Text(
                              error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _VoiceActionButton(
                    isListening: isListening,
                    isSpeaking: isSpeaking,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _statusText(VoiceChatState state) {
    if (state is VoiceChatLoadingState && state.isLoading) {
      return 'Starting voice session...';
    }
    if (state is ReceivingVoiceState) return 'Listening...';
    if (state is SendingVoiceState) return 'Assistant is speaking...';
    if (state is StopMicState) return 'Stopped';
    if (state is VoiceChatError) return 'Voice chat stopped';
    return 'Tap start and speak';
  }
}

class _VoiceActionButton extends StatelessWidget {
  const _VoiceActionButton({
    required this.isListening,
    required this.isSpeaking,
  });

  final bool isListening;
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VoiceChatCubit>();

    return SizedBox(
      width: 88,
      height: 88,
      child: ElevatedButton(
        onPressed: (isSpeaking || isListening) ? null : cubit.startVoiceChat,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: isSpeaking
              ? Colors.grey
              : isListening
              ? Colors.redAccent
              : const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        child: Icon(
          isSpeaking
              ? Icons.volume_up_rounded
              : isListening
              ? Icons.graphic_eq_rounded
              : Icons.mic_rounded,
        ),
      ),
    );
  }
}

class _PulseMic extends StatelessWidget {
  const _PulseMic({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isActive ? 144 : 124,
      height: isActive ? 144 : 124,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.redAccent.withValues(alpha: 0.12) : null,
        border: Border.all(
          color: isActive ? Colors.redAccent : const Color(0xFF2563EB),
          width: 2,
        ),
      ),
      child: Icon(
        isActive ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
        size: 48,
        color: isActive ? Colors.redAccent : const Color(0xFF2563EB),
      ),
    );
  }
}
