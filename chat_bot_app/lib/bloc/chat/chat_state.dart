import 'package:chat_bot_app/model/app_models.dart';
import 'package:equatable/equatable.dart';

enum ChatStatus { initial, sending, success, failure }

class ChatState extends Equatable {
  final List<Message> messages;
  final String input;
  final ChatStatus status;
  final String? errorMessage;
  final String sessionId;
  final bool isAssistantLoading;

  const ChatState({
    required this.messages,
    required this.input,
    required this.status,
    required this.sessionId,
    required this.isAssistantLoading,
    this.errorMessage,
  });

  const ChatState.initial()
      : messages = const [],
        input = '',
        status = ChatStatus.initial,
        errorMessage = null,
        sessionId = '',
        isAssistantLoading = false;

  ChatState copyWith({
    List<Message>? messages,
    String? input,
    ChatStatus? status,
    String? errorMessage,
    String? sessionId,
    bool? isAssistantLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      input: input ?? this.input,
      status: status ?? this.status,
      errorMessage: errorMessage,
      sessionId: sessionId ?? this.sessionId,
      isAssistantLoading: isAssistantLoading ?? this.isAssistantLoading,
    );
  }

  bool get canSend => input.trim().isNotEmpty && status != ChatStatus.sending;

  @override
  List<Object?> get props => [
    messages,
    input,
    status,
    errorMessage,
    sessionId,
    isAssistantLoading,
  ];
}
