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
  int _lastLevelLogMs = 0;
  DateTime? _lastVoiceAt;
  DateTime? _recordingStartedAt;
  Timer? _silenceWatchdog;

  static const double _voiceLevelThreshold = 2.0;
  static const int _silenceHoldMs = 900;
  static const int _minRecordingBeforeStopMs = 500;
  static const int _captureTimeoutMs = 12000;
  static const int _watchdogIntervalMs = 60;

  VoiceChatCubit() : super(VoiceChatInitial()) {
    _audioService = AudioService(
      onPlaybackFinished: _onPlaybackDone,
      onSoundLevel: _handleSoundLevel,
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

  void _handleSoundLevel(double level) {
    if (!_isListening || _isBotSpeaking || _isStopping) return;

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    if (nowMs - _lastLevelLogMs >= 500) {
      _lastLevelLogMs = nowMs;
      // ignore: avoid_print
      print(
        '[VoiceChatCubit] sound level -> level=${level.toStringAsFixed(1)} listening=$_isListening speaking=$_isBotSpeaking',
      );
    }

    if (level >= _voiceLevelThreshold) {
      _hasVoice = true;
      _lastVoiceAt = now;
      return;
    }

    if (!_hasVoice) return;

    final recordingStartedAt = _recordingStartedAt;
    final lastVoiceAt = _lastVoiceAt;
    if (recordingStartedAt == null || lastVoiceAt == null) return;

    final recordingMs = now.difference(recordingStartedAt).inMilliseconds;
    final silenceMs = now.difference(lastVoiceAt).inMilliseconds;
    if (recordingMs < _minRecordingBeforeStopMs) return;

    if (silenceMs >= _silenceHoldMs) {
      // ignore: avoid_print
      print(
        '[VoiceChatCubit] silence detected -> stopRecording() silenceMs=$silenceMs recordingMs=$recordingMs level=${level.toStringAsFixed(1)}',
      );
      stopRecording();
      return;
    }

    if (recordingMs >= _captureTimeoutMs) {
      // ignore: avoid_print
      print(
        '[VoiceChatCubit] capture timeout -> stopRecording() recordingMs=$recordingMs',
      );
      stopRecording();
    }
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
      }
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (_chatStarted && !_isBotSpeaking) {
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
      _lastLevelLogMs = 0;
      _lastVoiceAt = null;
      _recordingStartedAt = DateTime.now();

      await _audioService.startRecording();
      _startSilenceWatchdog();

      // ignore: avoid_print
      print('[VoiceChatCubit] recording started');
      emit(ReceivingVoiceState());
    } catch (e) {
      // ignore: avoid_print
      print('[VoiceChatCubit] recording error -> $e');
      _isListening = false;
      _cancelSilenceWatchdog();
      emit(VoiceChatError('Recording error: ${e.toString()}'));
    }
  }

  Future<void> stopRecording() async {
    if (!_isListening || _isStopping) return;

    try {
      _isStopping = true;
      _cancelSilenceWatchdog();
      // ignore: avoid_print
      print('[VoiceChatCubit] stopRecording()');

      final base64Audio = await _audioService.stopRecording();
      if (base64Audio != null && base64Audio.isNotEmpty) {
        // ignore: avoid_print
        print(
          '[VoiceChatCubit] sending voice audio -> ${base64Audio.length} chars',
        );
        _socketService.sendVoiceAudio(
          base64Audio: base64Audio,
          mimeType: 'audio/wav',
          filename: 'voice.wav',
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
    _cancelSilenceWatchdog();
    await _audioService.dispose();
    _socketService.disconnect();
    return super.close();
  }

  void _startSilenceWatchdog() {
    _cancelSilenceWatchdog();
    _silenceWatchdog = Timer.periodic(
      const Duration(milliseconds: _watchdogIntervalMs),
      (_) => _checkSilenceWatchdog(),
    );
  }

  void _cancelSilenceWatchdog() {
    _silenceWatchdog?.cancel();
    _silenceWatchdog = null;
  }

  void _checkSilenceWatchdog() {
    if (!_isListening || _isBotSpeaking || _isStopping) return;
    if (!_hasVoice) return;

    final recordingStartedAt = _recordingStartedAt;
    final lastVoiceAt = _lastVoiceAt;
    if (recordingStartedAt == null || lastVoiceAt == null) return;

    final now = DateTime.now();
    final recordingMs = now.difference(recordingStartedAt).inMilliseconds;
    final silenceMs = now.difference(lastVoiceAt).inMilliseconds;
    if (recordingMs < _minRecordingBeforeStopMs) return;

    if (silenceMs >= _silenceHoldMs) {
      // ignore: avoid_print
      print(
        '[VoiceChatCubit] watchdog silence -> stopRecording() silenceMs=$silenceMs recordingMs=$recordingMs',
      );
      stopRecording();
      return;
    }

    if (recordingMs >= _captureTimeoutMs) {
      // ignore: avoid_print
      print(
        '[VoiceChatCubit] watchdog capture timeout -> stopRecording() recordingMs=$recordingMs',
      );
      stopRecording();
    }
  }
}
