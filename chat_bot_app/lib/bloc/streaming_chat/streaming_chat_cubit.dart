import 'dart:developer';

import 'package:chat_bot_app/bloc/streaming_chat/streaming_chat_state.dart';
import 'package:chat_bot_app/constants/api_constants.dart';
import 'package:chat_bot_app/model/app_models.dart';
import 'package:chat_bot_app/services/audio_service.dart';
import 'package:chat_bot_app/services/socket_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class StreamingChatCubit extends Cubit<StreamingChatState> {
  final SocketService _socketService = SocketService();
  late final AudioService _audioService;

  StreamingChatCubit() : super(const StreamingChatState.initial()) {
    _audioService = AudioService(onBase64AudioData: (_) {});
  }

  void _debug(String message) {
    if (ApiConstants.enableSocketDebugLogs) {
      log('[StreamingCubit] $message');
    }
  }

  Future<void> bootstrap() async {
    final sessionId = const Uuid().v4();
    _debug('bootstrap() -> sessionId=$sessionId');

    emit(
      state.copyWith(
        sessionId: sessionId,
        status: StreamingChatStatus.connecting,
      ),
    );

    _socketService.init(
      onConnect: () {
        _debug('connected');
        emit(
          state.copyWith(
            status: StreamingChatStatus.connected,
            errorMessage: null,
          ),
        );
      },
      onError: (error) {
        _debug('socket_error -> $error');
        emit(
          state.copyWith(
            status: StreamingChatStatus.failure,
            errorMessage: error.toString(),
            isAssistantTyping: false,
          ),
        );
      },
      onDisconnect: () {
        _debug('disconnected');
        emit(state.copyWith(status: StreamingChatStatus.initial));
      },
      onMessage: (text) {
        _debug('received -> ${text.replaceAll('\n', ' ').trim()}');

        final messages = List.of(state.messages);

        if (messages.isNotEmpty && messages.last.isLoading) {
          // Replace loader with the first chunk
          messages.removeLast();
          messages.add(
            Message(
              id: const Uuid().v4(),
              text: text,
              role: 'assistant',
              timestamp: DateTime.now(),
              isFromAdmin: true,
              fromAi: true,
            ),
          );
        } else if (messages.isNotEmpty && messages.last.role == 'assistant') {
          // Append chunk to the last assistant message
          final last = messages.removeLast();
          messages.add(last.copyWith(text: last.text + text));
        } else {
          // Fallback: add as a new message
          messages.add(
            Message(
              id: const Uuid().v4(),
              text: text,
              role: 'assistant',
              timestamp: DateTime.now(),
              isFromAdmin: true,
              fromAi: true,
            ),
          );
        }

        emit(
          state.copyWith(
            messages: messages,
            status: StreamingChatStatus.connected,
            isAssistantTyping: false,
          ),
        );
      },
      onDone: () {
        _debug('done');
        emit(
          state.copyWith(
            status: StreamingChatStatus.connected,
            isAssistantTyping: false,
          ),
        );
      },
      onAudioChunk: (chunk) {
        _debug('audio chunk -> ${chunk.length} bytes');
        _audioService.playAudio(chunk);
      },
    );

    await _socketService.connect(
      serverUrl: ApiConstants.socketUrl,
      sessionId: sessionId,
    );
  }

  void onInputChanged(String value) {
    emit(state.copyWith(input: value, errorMessage: null));
  }

  Future<bool> sendMessage() async {
    final text = state.input.trim();
    if (text.isEmpty || state.status == StreamingChatStatus.sending) {
      return false;
    }

    final userMessage = Message(
      id: const Uuid().v4(),
      text: text,
      role: 'user',
      timestamp: DateTime.now(),
      fromAi: false,
      isFromAdmin: false,
    );

    final messages = List.of(state.messages)
      ..add(userMessage)
      ..add(
        Message(
          id: const Uuid().v4(),
          text: '',
          role: 'assistant',
          timestamp: DateTime.now(),
          isFromAdmin: true,
          fromAi: true,
          isLoading: true,
        ),
      );

    emit(
      state.copyWith(
        messages: messages,
        input: '',
        status: StreamingChatStatus.sending,
        errorMessage: null,
        isAssistantTyping: true,
      ),
    );

    _socketService.sendMessage(text);
    return true;
  }

  Future<void> startNewChat() async {
    _socketService.disconnect();
    emit(const StreamingChatState.initial());
    await bootstrap();
  }

  @override
  Future<void> close() {
    _socketService.disconnect();
    _audioService.dispose();
    return super.close();
  }
}
