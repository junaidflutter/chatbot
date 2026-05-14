// voice_chat_states.dart
import 'package:equatable/equatable.dart';

abstract class VoiceChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VoiceChatInitial extends VoiceChatState {}

class SendingVoiceState extends VoiceChatState {}

class ReceivingVoiceState extends VoiceChatState {}

class VoiceReceived extends VoiceChatState {}

class ChatLoaded extends VoiceChatState {}

class StopMicState extends VoiceChatState {}

class VoiceChatLoadingState extends VoiceChatState {
  final bool isLoading;

  VoiceChatLoadingState(this.isLoading);

  @override
  List<Object?> get props => [isLoading];
}

class VoiceChatError extends VoiceChatState {
  final String error;

  VoiceChatError(this.error);

  @override
  List<Object?> get props => [error];
}
