import 'package:chat_bot_app/constants/api_constants.dart';
import 'package:chat_bot_app/model/app_models.dart';
import 'package:chat_bot_app/utils/server.dart';

class ChatApiProvider {
  const ChatApiProvider();

  Future<ChatReply> sendMessage({
    required String question,
    String? sessionId,
  }) async {
    final response = await Server.post(
      ApiConstants.chat,
      data: {
        'question': question,
        'session_id': sessionId ?? 'default',
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ChatReply.fromJson(data);
    }
    if (data is Map) {
      return ChatReply.fromJson(Map<String, dynamic>.from(data));
    }
    throw 'Invalid chat response';
  }
}
