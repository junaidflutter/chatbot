class ApiConstants {
  ApiConstants._();

  // Local dev server. Use your machine IP on a physical device.
  static const String devUrl = 'http://localhost:8000';

  // Auth
  static const String logInApi = '/auth/login';
  static const String signUp = '/auth/register';
  static const String me = '/auth/me';

  // Chat
  static const String chat = '/chat';
  static const String chatHistory = '/chat/history';

  // Documents
  static const String documentUpload = '/documents/upload';
  static const String documentList = '/documents';
  static const String documentView = '/documents/view';

  // Health
  static const String health = '/health';
  static const String voice = '/voice';

  // Socket.IO
  static const String socketUrl = devUrl;
  static const String socketPath = '/socket.io/';
  static const bool enableSocketDebugLogs = true;

  // Socket events
  static const String joinSession = 'user:join';
  static const String startStream = 'start_stream';
  static const String sendMessage = 'user:message';
  static const String voiceAudio = 'voice_audio';
  static const String audioChunk = 'audio_chunk';
  static const String audioEnd = 'audio_end';
  static const String voiceAudioChunk = audioChunk;
  static const String voiceAudioEnd = audioEnd;

  static const String sessionIdKey = 'conversationId';
  static const String questionKey = 'text';
  static const String accessTokenKey = 'access_token';

  static const String messageAck = 'message_ack';
  static const String assistantTyping = 'assistant_typing';
  static const String assistantChunk = 'assistant_chunk';
  static const String assistantDone = 'assistant_done';
  static const String assistantError = 'assistant_error';

  static const String voiceTranscribing = 'voice_transcribing';
  static const String voiceTranscript = 'voice_transcript';
  static const String audioResponse = 'audio_response';
  static const String audioBase64Key = 'audio_base64';
  static const String audioMimeTypeKey = 'mime_type';
  static const String audioFilenameKey = 'audio_filename';
  static const String audioChunkIndexKey = 'chunk_index';
  static const String audioCodecKey = 'audio_codec';
  static const String audioSampleRateKey = 'sample_rate';
  static const String audioNumChannelsKey = 'num_channels';
  static const String audioIsFinalKey = 'is_final';
}
