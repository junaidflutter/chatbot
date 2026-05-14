import 'dart:async';
import 'dart:convert'; // For base64Encode
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecorderReady = false;
  bool _isPlayerReady = false;
  StreamSubscription<RecordingDisposition>? _recorderProgressSub;
  StreamSubscription<Uint8List>? _recordingChunkSub;
  StreamController<Uint8List>? _recordingChunkController;
  BytesBuilder _recordingPcmBuffer = BytesBuilder(copy: false);
  int _recordingChunkCount = 0;
  static const int _recordingSampleRate = 16000;
  static const int _recordingNumChannels = 1;

  final Function(String)? onBase64AudioData;
  final Function(double)? onSoundLevel;
  VoidCallback? onPlaybackFinished;
  Completer<void>? _playbackCompleter;

  static const MethodChannel _platform = MethodChannel(
    'com.example.audio/routing',
  );

  final List<Uint8List> _audioQueue = [];
  bool _isPlaying = false;

  AudioService({
    this.onBase64AudioData,
    this.onSoundLevel,
    this.onPlaybackFinished,
  });

  Future<void> _initRecorder() async {
    if (_isRecorderReady) return;

    _recorder = FlutterSoundRecorder();
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    await _recorder!.openRecorder();
    _isRecorderReady = true;
    await _setSpeakerMode(true);
  }

  Future<void> _initPlayer() async {
    if (_isPlayerReady) return;

    _player = FlutterSoundPlayer();
    await _player!.openPlayer();
    _isPlayerReady = true;
    await _setSpeakerMode(true);
  }

  Future<void> _setSpeakerMode(bool enable) async {
    try {
      await _platform.invokeMethod('setSpeaker', {'enable': enable});
    } on MissingPluginException {
      return;
    } catch (e) {
      log('Error setting speaker mode: $e');
    }
  }

  Future<void> startRecording() async {
    await _initRecorder();
    if (_recorder?.isRecording ?? false) {
      return;
    }

    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 20));
    await _recorderProgressSub?.cancel();
    _recorderProgressSub = _recorder!.onProgress?.listen((event) {
      final decibels = event.decibels ?? -60.0;
      log('[AudioService] recorder progress -> db=$decibels');
      onSoundLevel?.call(decibels);
    });

    await _recordingChunkSub?.cancel();
    _recordingChunkSub = null;
    await _recordingChunkController?.close();
    _recordingChunkController = StreamController<Uint8List>();
    _recordingPcmBuffer = BytesBuilder(copy: false);
    _recordingChunkCount = 0;
    _recordingChunkSub = _recordingChunkController!.stream.listen((chunk) {
      if (chunk.isEmpty) return;
      _recordingPcmBuffer.add(chunk);
      _recordingChunkCount += 1;
      log(
        '[AudioService] recorder chunk -> ${chunk.length} bytes (#$_recordingChunkCount)',
      );
      onBase64AudioData?.call(base64Encode(chunk));
    });

    log('[AudioService] startRecorder()');
    await _recorder!.startRecorder(
      toStream: _recordingChunkController!.sink,
      codec: Codec.pcm16,
      numChannels: _recordingNumChannels,
      sampleRate: _recordingSampleRate,
      audioSource: AudioSource.microphone,
      bufferSize: 2048,
      enableEchoCancellation: true,
      enableNoiseSuppression: true,
    );
  }

  Future<String?> stopRecording({bool buildBase64 = true}) async {
    if (!_isRecorderReady || _recorder == null) return null;

    log('[AudioService] stopRecorder()');
    final _ = await _recorder!.stopRecorder();
    await _recorderProgressSub?.cancel();
    _recorderProgressSub = null;
    await _recordingChunkSub?.cancel();
    _recordingChunkSub = null;
    await _recordingChunkController?.close();
    _recordingChunkController = null;

    final pcmBytes = _recordingPcmBuffer.takeBytes();
    _recordingPcmBuffer = BytesBuilder(copy: false);
    if (pcmBytes.length < 256) {
      log('[AudioService] recording too short, ignoring');
      return null;
    }

    if (!buildBase64) {
      log('[AudioService] recording stopped without packaging');
      return null;
    }

    final wavBytes = _wrapPcm16ToWav(
      pcmBytes,
      sampleRate: _recordingSampleRate,
      channels: _recordingNumChannels,
    );
    log('[AudioService] recording pcm bytes -> ${pcmBytes.length}');
    log('[AudioService] recording wav bytes -> ${wavBytes.length}');
    final base64Audio = base64Encode(wavBytes);
    onBase64AudioData?.call(base64Audio);
    return base64Audio;
  }

  Future<void> playAudio(Uint8List audioData) async {
    if (audioData.isEmpty) return;

    log('[AudioService] playAudio bytes -> ${audioData.length}');
    _audioQueue.add(audioData);

    if (!_isPlaying) {
      _playbackCompleter = Completer<void>();
      await _processAudioQueue();
      _playbackCompleter?.complete();
      onPlaybackFinished?.call();
    }
    return _playbackCompleter?.future;
  }

  Future<void> _processAudioQueue() async {
    if (_audioQueue.isEmpty || _isPlaying) return;

    _isPlaying = true;
    try {
      await _initPlayer();
      await _player?.stopPlayer();

      while (_audioQueue.isNotEmpty) {
        final audioChunk = _audioQueue.removeAt(0);
        log('[AudioService] queue chunk -> ${audioChunk.length}');
        final finished = Completer<void>();

        await _player!.startPlayer(
          fromDataBuffer: audioChunk,
          codec: Codec.pcm16WAV,
          whenFinished: () {
            if (!finished.isCompleted) {
              finished.complete();
            }
          },
        );

        await finished.future;
      }
    } finally {
      await _player?.stopPlayer();
      _isPlaying = false;
    }
  }

  Future<void> dispose() async {
    await stopRecording(buildBase64: false);
    await _player?.stopPlayer();
    await _recorder?.closeRecorder();
    await _player?.closePlayer();
    await _recorderProgressSub?.cancel();
    _recorderProgressSub = null;
    await _recordingChunkSub?.cancel();
    _recordingChunkSub = null;
    await _recordingChunkController?.close();
    _recordingChunkController = null;

    _audioQueue.clear();
    _isRecorderReady = false;
    _isPlayerReady = false;
    _recorder = null;
    _player = null;
  }

  Uint8List _wrapPcm16ToWav(
    Uint8List pcmBytes, {
    required int sampleRate,
    required int channels,
  }) {
    const int bytesPerSample = 2;
    final int dataSize = pcmBytes.length;
    final int byteRate = sampleRate * channels * bytesPerSample;
    final int blockAlign = channels * bytesPerSample;
    final int riffChunkSize = 36 + dataSize;

    final builder = BytesBuilder(copy: false);
    final header = ByteData(44);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i += 1) {
        header.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    header.setUint32(4, riffChunkSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bytesPerSample * 8, Endian.little);
    writeAscii(36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    builder.add(header.buffer.asUint8List());
    builder.add(pcmBytes);
    return builder.toBytes();
  }
}
