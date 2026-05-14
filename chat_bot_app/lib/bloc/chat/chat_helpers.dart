import 'package:chat_bot_app/model/app_models.dart';
import 'package:uuid/uuid.dart';

Message buildUserMessage(String text) {
  return Message(
    id: const Uuid().v4(),
    text: text,
    role: 'user',
    timestamp: DateTime.now(),
    fromAi: false,
    isFromAdmin: false,
  );
}

Message buildAssistantLoadingMessage() {
  return Message(
    text: '',
    role: 'assistant',
    timestamp: DateTime.now(),
    fromAi: true,
    isFromAdmin: true,
    isLoading: true,
  );
}

Message buildAssistantMessage(ChatReply reply) {
  return Message(
    id: const Uuid().v4(),
    text: reply.answer,
    role: 'assistant',
    timestamp: DateTime.now(),
    fromDocument: reply.fromDocument,
    fromAi: reply.fromAi,
    isFromAdmin: true,
  );
}
