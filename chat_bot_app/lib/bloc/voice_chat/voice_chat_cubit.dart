import 'dart:async';
import 'dart:typed_data';

import 'package:chat_bot_app/bloc/voice_chat/voice_chat_state.dart';
import 'package:chat_bot_app/constants/api_constants.dart';
import 'package:chat_bot_app/services/audio_service.dart';
import 'package:chat_bot_app/services/socket_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VoiceChatCubit extends Cubit<VoiceChatState> {
  late final AudioService _audioService;
  final SocketService _socketService = SocketService();

  bool _isListening = false;
  bool _isBotSpeaking = false;
  bool _chatStarted = false;
  bool _awaitingInitialGreeting = true;
  bool _voiceSessionStarted = false;
  bool _isStopping = false;
  bool _hasVoice = false;
  int _voiceChunkIndex = 0;
  DateTime? _lastVoiceAt;
  DateTime? _recordingStartedAt;

  VoiceChatCubit() : super(VoiceChatInitial()) {
    _audioService = AudioService(
      onPlaybackFinished: _onPlaybackDone,
      onSoundLevel: _handleSoundLevel,
      onBase64AudioData: _handleBase64AudioData,
    );
    _initConnection();
  }

  bool get isListening => _isListening;
  bool get isBotSpeaking => _isBotSpeaking;

  void _initConnection() {
    emit(VoiceChatLoadingState(true));
    // ignore: avoid_print
    print('[VoiceChatCubit] initConnection()');

    _socketService.init(
      onAudioChunk: _handleBotAudio,
      onConnect: () {
        // ignore: avoid_print
        print('[VoiceChatCubit] socket connected');
        emit(VoiceChatInitial());
      },
      onError: (error) {
        // ignore: avoid_print
        print('[VoiceChatCubit] socket error -> $error');
        emit(VoiceChatError('Connection error: $error'));
      },
      onDisconnect: () {
        // ignore: avoid_print
        print('[VoiceChatCubit] socket disconnected');
        emit(VoiceChatError('Disconnected from server'));
      },
    );

    _socketService.connect(serverUrl: ApiConstants.socketUrl);
  }

  void _handleSoundLevel(double levelDb) {
    if (!_isListening || _isBotSpeaking || _isStopping) return;

    // ignore: avoid_print
    print(
      '[VoiceChatCubit] sound level -> levelDb=${levelDb.toStringAsFixed(2)} listening=$_isListening speaking=$_isBotSpeaking',
    );

    if (levelDb >= 2.5) {
      _hasVoice = true;
      final now = DateTime.now();
      _lastVoiceAt = now;
      return;
    }

    if (!_hasVoice) {
      return;
    }

    final lastVoiceAt = _lastVoiceAt;
    if (lastVoiceAt == null) {
      final startedAt = _recordingStartedAt;
      if (startedAt != null &&
          DateTime.now().difference(startedAt).inMilliseconds >= 5000 &&
          _voiceChunkIndex > 0) {
        print('[VoiceChatCubit] hard timeout -> stopRecording()');
        stopRecording();
      }
      return;
    }

    final now = DateTime.now();
    final silenceMs = now.difference(lastVoiceAt).inMilliseconds;
    if (silenceMs >= 180) {
      _lastVoiceAt = null;
      // ignore: avoid_print
      print('[VoiceChatCubit] silence detected -> stopRecording()');
      stopRecording();
    }
  }

  void _handleBase64AudioData(String base64Audio) {
    if (!_isListening || _isBotSpeaking || _isStopping) return;
    if (base64Audio.isEmpty) return;

    final chunkIndex = _voiceChunkIndex++;
    // ignore: avoid_print
    print(
      '[VoiceChatCubit] voice chunk -> index=$chunkIndex chars=${base64Audio.length}',
    );
    _socketService.sendAudioChunk(
      base64Audio,
      chunkIndex: chunkIndex,
      sampleRate: 16000,
      numChannels: 1,
      codec: 'pcm16',
    );
  }

  Future<void> _handleBotAudio(Uint8List data) async {
    // ignore: avoid_print
    print('[VoiceChatCubit] bot audio bytes -> ${data.length}');
    if (!_isBotSpeaking) {
      _isBotSpeaking = true;
      _isListening = false;
      emit(SendingVoiceState());
    }

    try {
      await _audioService.playAudio(data);
    } catch (e) {
      _isBotSpeaking = false;
      if (_chatStarted) {
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (_chatStarted && !_isBotSpeaking) {
            startRecording();
          }
        });
      }
      emit(VoiceChatError('Playback error: ${e.toString()}'));
    }
  }

  void _onPlaybackDone() {
    _isBotSpeaking = false;
    emit(VoiceChatInitial());
    if (_chatStarted) {
      if (_awaitingInitialGreeting) {
        _awaitingInitialGreeting = false;
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (_chatStarted && !_isBotSpeaking) {
            startRecording();
          }
        });
        return;
      }
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (_chatStarted && !_isBotSpeaking && !_awaitingInitialGreeting) {
          startRecording();
        }
      });
    }
  }

  Future<void> startVoiceChat() async {
    if (_voiceSessionStarted) return;

    _chatStarted = true;
    _awaitingInitialGreeting = true;
    _voiceSessionStarted = true;
    _socketService.startVoiceSession();
    emit(VoiceChatLoadingState(true));
  }

  Future<void> startRecording() async {
    if (_isBotSpeaking || _isListening || _isStopping) return;

    try {
      // ignore: avoid_print
      print('[VoiceChatCubit] startRecording()');
      _isListening = true;
      _hasVoice = false;
      _voiceChunkIndex = 0;
      _lastVoiceAt = null;
      _recordingStartedAt = DateTime.now();

      await _audioService.startRecording();

      // ignore: avoid_print
      print('[VoiceChatCubit] recording started');
      emit(ReceivingVoiceState());
    } catch (e) {
      // ignore: avoid_print
      print('[VoiceChatCubit] recording error -> $e');
      _isListening = false;
      emit(VoiceChatError('Recording error: ${e.toString()}'));
    }
  }

  Future<void> stopRecording() async {
    if (!_isListening || _isStopping) return;

    try {
      _isStopping = true;
      // ignore: avoid_print
      print('[VoiceChatCubit] stopRecording()');
      await _audioService.stopRecording(buildBase64: false);

      if (_voiceChunkIndex > 0) {
        _socketService.sendAudioEnd(
          chunkCount: _voiceChunkIndex,
          sampleRate: 16000,
          numChannels: 1,
          codec: 'pcm16',
          filename: 'voice.wav',
          isFinal: true,
        );
      } else {
        // ignore: avoid_print
        print('[VoiceChatCubit] stopRecording() ignored empty capture');
      }

      _isListening = false;
      _hasVoice = false;
      _lastVoiceAt = null;
      _recordingStartedAt = null;
      emit(StopMicState());
    } catch (e) {
      // ignore: avoid_print
      print('[VoiceChatCubit] stopRecording error -> $e');
      emit(VoiceChatError('Stop recording error: ${e.toString()}'));
    } finally {
      _isStopping = false;
    }
  }

  @override
  Future<void> close() async {
    await _audioService.dispose();
    _socketService.disconnect();
    return super.close();
  }
}
