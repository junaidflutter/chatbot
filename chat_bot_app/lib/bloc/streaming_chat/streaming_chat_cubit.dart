import 'dart:async';
import 'dart:developer';

import 'package:chat_bot_app/bloc/streaming_chat/streaming_chat_state.dart';
import 'package:chat_bot_app/constants/api_constants.dart';
import 'package:chat_bot_app/model/app_models.dart';
import 'package:chat_bot_app/services/chat_api_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class StreamingChatCubit extends Cubit<StreamingChatState> {
  final ChatApiProvider _chatApiProvider = const ChatApiProvider();

  StreamingChatCubit() : super(const StreamingChatState.initial());

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
        status: StreamingChatStatus.connected,
        errorMessage: null,
      ),
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

    unawaited(_streamAssistantResponse(text));
    return true;
  }

  Future<void> startNewChat() async {
    emit(const StreamingChatState.initial());
    await bootstrap();
  }

  Future<void> _streamAssistantResponse(String text) async {
    try {
      await for (final chunk in _chatApiProvider.streamMessage(
        question: text,
        sessionId: state.sessionId,
      )) {
        _debug('api chunk -> ${chunk.replaceAll('\n', ' ').trim()}');
        _appendAssistantChunk(chunk);
      }

      emit(
        state.copyWith(
          status: StreamingChatStatus.connected,
          isAssistantTyping: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      _debug('api_error -> $error');
      final updatedMessages = List.of(state.messages);
      if (updatedMessages.isNotEmpty && updatedMessages.last.isLoading) {
        updatedMessages.removeLast();
      }
      emit(
        state.copyWith(
          messages: updatedMessages,
          status: StreamingChatStatus.failure,
          errorMessage: error.toString(),
          isAssistantTyping: false,
        ),
      );
    }
  }

  void _appendAssistantChunk(String text) {
    final messages = List.of(state.messages);

    if (messages.isNotEmpty && messages.last.isLoading) {
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
      final last = messages.removeLast();
      messages.add(last.copyWith(text: last.text + text));
    } else {
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
        status: StreamingChatStatus.sending,
        isAssistantTyping: false,
        errorMessage: null,
      ),
    );
  }
}
