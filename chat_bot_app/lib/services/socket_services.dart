import 'dart:convert';
import 'dart:developer';

import 'package:chat_bot_app/constants/api_constants.dart';
import 'package:chat_bot_app/utils/my_pref.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:uuid/uuid.dart';

class SocketService {
  io.Socket? _socket;
  String? _conversationId;

  late VoidCallback onConnect;
  late ValueChanged<dynamic> onError;
  late VoidCallback onDisconnect;
  late VoidCallback onDone;
  late ValueChanged<String> onMessage;
  ValueChanged<Uint8List>? onAudioChunk;

  void init({
    required VoidCallback onConnect,
    required ValueChanged<dynamic> onError,
    required VoidCallback onDisconnect,
    VoidCallback? onDone,
    ValueChanged<String>? onMessage,
    ValueChanged<Uint8List>? onAudioChunk,
  }) {
    this.onConnect = onConnect;
    this.onError = onError;
    this.onDisconnect = onDisconnect;
    this.onDone = onDone ?? () {};
    this.onMessage = onMessage ?? (_) {};
    this.onAudioChunk = onAudioChunk;
  }

  Future<String> bootstrapSessionId() async {
    _conversationId = const Uuid().v4();
    log('[SocketService] session_id=$_conversationId');
    return _conversationId!;
  }

  Future<void> connect({
    String serverUrl = ApiConstants.socketUrl,
    String? sessionId,
  }) async {
    if (_socket != null) return;
    _conversationId =
        sessionId ?? _conversationId ?? await bootstrapSessionId();

    log(
      '[SocketService] connect -> $serverUrl/socket.io/?EIO=4&transport=polling',
    );

    _socket = io.io(serverUrl, {
      'path': '/socket.io/',
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
    });

    _socket?.onConnect((_) {
      log('[SocketService] connected');
      _socket?.emit(ApiConstants.joinSession, _socketPayload());
      log('[SocketService] emitted join_session');
      onConnect();
    });

    _socket?.onDisconnect((_) {
      log('[SocketService] disconnected');
      onDisconnect();
    });

    _socket?.onConnectError((error) {
      log('[SocketService] connect_error -> $error');
      onError(error);
    });

    _socket?.on(ApiConstants.assistantError, (data) {
      final error = _extractError(data);
      log('[SocketService] assistant_error -> $error');
      onError(error);
    });

    _socket?.on(ApiConstants.assistantChunk, (data) {
      final text = _extractText(data);
      if (text.isNotEmpty) {
        log('[SocketService] assistant_chunk -> ${_short(text)}');
        onMessage(text);
      }
    });

    _socket?.on(ApiConstants.assistantDone, (_) {
      log('[SocketService] assistant_done');
      onDone();
    });

    _socket?.on(ApiConstants.audioResponse, (data) {
      final audio = _extractAudioBytes(data);
      if (audio.isNotEmpty) {
        log('[SocketService] audio_response -> ${audio.length} bytes');
        onAudioChunk?.call(audio);
      } else {
        log('[SocketService] audio_response received but empty');
      }
    });
  }

  void sendMessage(String text) {
    if (_socket == null || !(_socket?.connected ?? false)) {
      log('[SocketService] send blocked -> not connected');
      return;
    }

    log('[SocketService] message sending -> $text');
    _socket?.emit(ApiConstants.sendMessage, _socketPayload(text: text));
    log('[SocketService] message sent');
  }

  void startVoiceSession() {
    if (_socket == null || !(_socket?.connected ?? false)) {
      log('[SocketService] start voice blocked -> not connected');
      return;
    }

    _socket?.emit(ApiConstants.startStream, _socketPayload());
    log('[SocketService] emitted start_stream');
  }

  void sendVoiceAudio({
    required String base64Audio,
    required String mimeType,
    required String filename,
  }) {
    if (_socket == null || !(_socket?.connected ?? false)) {
      log('[SocketService] voice send blocked -> not connected');
      return;
    }

    log('[SocketService] voice audio sending -> $mimeType');
    log(
      '[SocketService] voice audio payload size -> ${base64Audio.length} chars',
    );
    _socket?.emit(ApiConstants.voiceAudio, {
      ..._socketPayload(),
      ApiConstants.audioBase64Key: base64Audio,
      ApiConstants.audioMimeTypeKey: mimeType,
      ApiConstants.audioFilenameKey: filename,
    });
  }

  void sendVoiceAudioChunk({
    required String base64Chunk,
    required int chunkIndex,
    required int sampleRate,
    required int numChannels,
    required String codec,
  }) {
    if (_socket == null || !(_socket?.connected ?? false)) {
      log('[SocketService] voice chunk blocked -> not connected');
      return;
    }

    log(
      '[SocketService] voice chunk sending -> index=$chunkIndex size=${base64Chunk.length} chars',
    );
    _socket?.emit(ApiConstants.audioChunk, {
      ..._socketPayload(),
      ApiConstants.audioBase64Key: base64Chunk,
      ApiConstants.audioChunkIndexKey: chunkIndex,
      ApiConstants.audioSampleRateKey: sampleRate,
      ApiConstants.audioNumChannelsKey: numChannels,
      ApiConstants.audioCodecKey: codec,
    });
  }

  void sendAudioChunk(
    String base64Audio, {
    int chunkIndex = 0,
    int sampleRate = 16000,
    int numChannels = 1,
    String codec = 'pcm16',
  }) {
    sendVoiceAudioChunk(
      base64Chunk: base64Audio,
      chunkIndex: chunkIndex,
      sampleRate: sampleRate,
      numChannels: numChannels,
      codec: codec,
    );
  }

  void sendVoiceAudioEnd({
    required int chunkCount,
    required int sampleRate,
    required int numChannels,
    required String codec,
    required String filename,
    bool isFinal = true,
  }) {
    if (_socket == null || !(_socket?.connected ?? false)) {
      log('[SocketService] voice end blocked -> not connected');
      return;
    }

    log('[SocketService] voice audio end -> chunks=$chunkCount final=$isFinal');
    _socket?.emit(ApiConstants.audioEnd, {
      ..._socketPayload(),
      ApiConstants.audioChunkIndexKey: chunkCount,
      ApiConstants.audioSampleRateKey: sampleRate,
      ApiConstants.audioNumChannelsKey: numChannels,
      ApiConstants.audioCodecKey: codec,
      ApiConstants.audioFilenameKey: filename,
      ApiConstants.audioIsFinalKey: isFinal,
    });
  }

  void sendAudioEnd({
    required int chunkCount,
    required int sampleRate,
    required int numChannels,
    required String codec,
    required String filename,
    bool isFinal = true,
  }) {
    sendVoiceAudioEnd(
      chunkCount: chunkCount,
      sampleRate: sampleRate,
      numChannels: numChannels,
      codec: codec,
      filename: filename,
      isFinal: isFinal,
    );
  }

  void disconnect() {
    log('[SocketService] disconnect()');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  Uint8List _extractAudioBytes(dynamic data) {
    try {
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
      if (data is String) return base64Decode(_stripDataUrl(data));
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final value =
            map['audio'] ??
            map['audio_base64'] ??
            map['chunk'] ??
            map['data'] ??
            map['bytes'];
        if (value is Uint8List) return value;
        if (value is List<int>) return Uint8List.fromList(value);
        if (value is String) return base64Decode(_stripDataUrl(value));
      }
    } catch (error) {
      log('[SocketService] audio decode failed -> $error');
    }
    return Uint8List(0);
  }

  Map<String, dynamic> _socketPayload({String? text}) {
    return {
      ApiConstants.sessionIdKey: _conversationId,
      ...?text == null ? null : {ApiConstants.questionKey: text},
      ApiConstants.accessTokenKey:
          MyPrefs.getAuthToken() ?? MyPrefs.getUserToken() ?? '',
    };
  }

  String _extractError(dynamic data) {
    if (data is String) return data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      return map['error']?.toString() ??
          map['message']?.toString() ??
          'Socket error';
    }
    return data?.toString() ?? 'Socket error';
  }

  String _stripDataUrl(String value) {
    if (value.startsWith('data:') && value.contains(',')) {
      return value.substring(value.indexOf(',') + 1);
    }
    return value;
  }

  String _extractText(dynamic data) {
    if (data is String) return data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      return map['chunk']?.toString() ??
          map['text']?.toString() ??
          map['message']?.toString() ??
          '';
    }
    return '';
  }

  String _short(String value, {int limit = 80}) {
    final text = value.replaceAll('\n', ' ').trim();
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }
}
