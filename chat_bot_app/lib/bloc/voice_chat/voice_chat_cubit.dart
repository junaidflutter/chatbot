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
  int _speechFrameCount = 0;
  int _lastLevelLogMs = 0;
  int _lastChunkLogMs = 0;
  DateTime? _lastVoiceAt;
  DateTime? _recordingStartedAt;

  static const double _voiceStartLevelDb = -42.0;
  static const int _speechFramesToStart = 2;
  static const int _silenceToStopMs = 350;
  static const int _hardStopMs = 4500;

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

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    if (nowMs - _lastLevelLogMs >= 500) {
      _lastLevelLogMs = nowMs;
      // ignore: avoid_print
      print(
        '[VoiceChatCubit] sound level -> levelDb=${levelDb.toStringAsFixed(1)} listening=$_isListening speaking=$_isBotSpeaking',
      );
    }

    if (levelDb >= _voiceStartLevelDb) {
      _speechFrameCount += 1;
      if (_speechFrameCount < _speechFramesToStart) return;
      if (!_hasVoice) {
        // ignore: avoid_print
        print('[VoiceChatCubit] human voice started');
      }
      _hasVoice = true;
      _lastVoiceAt = now;
      return;
    }

    _speechFrameCount = 0;
    if (!_hasVoice) {
      return;
    }

    final lastVoiceAt = _lastVoiceAt;
    if (lastVoiceAt == null) {
      final startedAt = _recordingStartedAt;
      if (startedAt != null &&
          now.difference(startedAt).inMilliseconds >= _hardStopMs &&
          _voiceChunkIndex > 0) {
        // ignore: avoid_print
        print('[VoiceChatCubit] hard timeout -> stopRecording()');
        stopRecording();
      }
      return;
    }

    final silenceMs = now.difference(lastVoiceAt).inMilliseconds;
    if (silenceMs >= _silenceToStopMs) {
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
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastChunkLogMs >= 500) {
      _lastChunkLogMs = nowMs;
      // ignore: avoid_print
      print(
        '[VoiceChatCubit] voice chunk -> index=$chunkIndex chars=${base64Audio.length}',
      );
    }
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
      _speechFrameCount = 0;
      _voiceChunkIndex = 0;
      _lastLevelLogMs = 0;
      _lastChunkLogMs = 0;
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
      _speechFrameCount = 0;
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
