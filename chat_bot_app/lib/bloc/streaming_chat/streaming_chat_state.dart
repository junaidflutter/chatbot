import 'package:chat_bot_app/model/app_models.dart';
import 'package:equatable/equatable.dart';

enum StreamingChatStatus { initial, connecting, connected, sending, failure }

class StreamingChatState extends Equatable {
  final List<Message> messages;
  final String input;
  final StreamingChatStatus status;
  final String sessionId;
  final String? errorMessage;
  final bool isAssistantTyping;
  final String streamedText;

  const StreamingChatState({
    required this.messages,
    required this.input,
    required this.status,
    required this.sessionId,
    required this.isAssistantTyping,
    required this.streamedText,
    this.errorMessage,
  });

  const StreamingChatState.initial()
      : messages = const [],
        input = '',
        status = StreamingChatStatus.initial,
        sessionId = '',
        errorMessage = null,
        isAssistantTyping = false,
        streamedText = '';

  StreamingChatState copyWith({
    List<Message>? messages,
    String? input,
    StreamingChatStatus? status,
    String? sessionId,
    String? errorMessage,
    bool? isAssistantTyping,
    String? streamedText,
  }) {
    return StreamingChatState(
      messages: messages ?? this.messages,
      input: input ?? this.input,
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      errorMessage: errorMessage,
      isAssistantTyping: isAssistantTyping ?? this.isAssistantTyping,
      streamedText: streamedText ?? this.streamedText,
    );
  }

  bool get canSend =>
      input.trim().isNotEmpty && status != StreamingChatStatus.sending;

  @override
  List<Object?> get props => [
    messages,
    input,
    status,
    sessionId,
    errorMessage,
    isAssistantTyping,
    streamedText,
  ];
}
