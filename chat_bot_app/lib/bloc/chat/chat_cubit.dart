import 'package:chat_bot_app/bloc/chat/chat_helpers.dart';
import 'package:chat_bot_app/bloc/chat/chat_state.dart';
import 'package:chat_bot_app/services/chat_api_provider.dart';
import 'package:chat_bot_app/utils/my_pref.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer';
import 'package:uuid/uuid.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatApiProvider _apiProvider;

  ChatCubit({ChatApiProvider? apiProvider})
      : _apiProvider = apiProvider ?? const ChatApiProvider(),
        super(const ChatState.initial());

  Future<void> bootstrap() async {
    final newConversationId = const Uuid().v4();
    await MyPrefs.setConversationId(newConversationId);
    log('[ChatCubit] bootstrap -> new sessionId=$newConversationId');
    emit(state.copyWith(sessionId: newConversationId));
  }

  Future<void> startNewChat() async {
    final newConversationId = const Uuid().v4();
    await MyPrefs.setConversationId(newConversationId);
    log('[ChatCubit] startNewChat -> new sessionId=$newConversationId');
    emit(
      const ChatState.initial().copyWith(
        sessionId: newConversationId,
        messages: const [],
        input: '',
        status: ChatStatus.initial,
        errorMessage: null,
        isAssistantLoading: false,
      ),
    );
  }

  void onInputChanged(String value) {
    emit(state.copyWith(input: value, errorMessage: null));
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  Future<bool> sendMessage() async {
    final text = state.input.trim();
    if (text.isEmpty || state.status == ChatStatus.sending) return false;

    final userMessage = buildUserMessage(text);
    final messagesAfterUser = List.of(state.messages)..add(userMessage);
    final loadingMessage = buildAssistantLoadingMessage();

    emit(
      state.copyWith(
        messages: [...messagesAfterUser, loadingMessage],
        input: '',
        status: ChatStatus.sending,
        errorMessage: null,
        isAssistantLoading: true,
      ),
    );

    try {
      final reply = await _apiProvider.sendMessage(
        question: text,
        sessionId: state.sessionId,
      );

      final assistantMessage = buildAssistantMessage(reply);
      final updatedMessages = List.of(messagesAfterUser)..add(assistantMessage);

      emit(
        state.copyWith(
          messages: updatedMessages,
          status: ChatStatus.success,
          isAssistantLoading: false,
          sessionId: state.sessionId,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          messages: messagesAfterUser,
          status: ChatStatus.failure,
          errorMessage: e.toString(),
          isAssistantLoading: false,
        ),
      );
      return false;
    }
  }
}
