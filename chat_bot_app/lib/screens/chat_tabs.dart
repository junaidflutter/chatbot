import 'package:chat_bot_app/screens/chat_screen.dart';
import 'package:chat_bot_app/screens/streaming_chat_screen.dart';
import 'package:chat_bot_app/screens/settings_screen.dart';
import 'package:chat_bot_app/screens/voice_chat_screen.dart';

class ChatTabs {
  static const chat = ChatScreen(
    title: 'Chat',
    subtitle: 'Standard chat workspace',
  );
  static const streamingChat = StreamingChatScreen();
  static const voiceChat = VoiceChatScreen();
  static const settings = SettingsScreen();
}
