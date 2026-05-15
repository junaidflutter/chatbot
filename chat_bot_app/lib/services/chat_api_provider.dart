import 'dart:convert';

import 'package:chat_bot_app/constants/api_constants.dart';
import 'package:chat_bot_app/model/app_models.dart';
import 'package:chat_bot_app/utils/server.dart';
import 'package:chat_bot_app/utils/my_pref.dart';
import 'package:dio/dio.dart';

class ChatApiProvider {
  const ChatApiProvider();

  Future<ChatReply> sendMessage({
    required String question,
    String? sessionId,
  }) async {
    final response = await Server.post(
      ApiConstants.chat,
      data: {'question': question, 'session_id': sessionId ?? 'default'},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ChatReply.fromJson(data);
    }
    if (data is Map) {
      return ChatReply.fromJson(Map<String, dynamic>.from(data));
    }
    throw 'Invalid chat response';
  }

  Stream<String> streamMessage({
    required String question,
    String? sessionId,
  }) async* {
    final dio = Dio(
      BaseOptions(
        baseUrl: _normalizeBaseUrl(ApiConstants.devUrl),
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/plain', 'Content-Type': 'application/json'},
      ),
    );

    final token = MyPrefs.getAuthToken() ?? MyPrefs.getUserToken();
    if (token?.isNotEmpty ?? false) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    final response = await dio.post<ResponseBody>(
      _normalizePath(ApiConstants.chatStream),
      data: {'question': question, 'session_id': sessionId ?? 'default'},
    );

    final body = response.data;
    if (body == null) {
      throw 'Empty stream response';
    }

    await for (final chunk in body.stream.map(
      (bytes) => utf8.decode(bytes, allowMalformed: true),
    )) {
      if (chunk.isNotEmpty) {
        yield chunk;
      }
    }
  }

  String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }

  String _normalizePath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }
}
