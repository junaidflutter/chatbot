import 'dart:developer';

import 'package:chat_bot_app/constants/api_constants.dart';
import 'package:chat_bot_app/model/app_models.dart';
import 'package:chat_bot_app/utils/my_pref.dart';
import 'package:dio/dio.dart';

class AuthService {
  static const String _tag = '[AuthService]';
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.devUrl,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<bool> login(String email, String password) async {
    try {
      log('$_tag login -> ${ApiConstants.logInApi}');

      final response = await _dio.post(
        ApiConstants.logInApi,
        data: {'email': email, 'password': password},
      );

      log('$_tag login response -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final token = data['access_token']?.toString() ?? '';
        final userMap = Map<String, dynamic>.from(data['user'] as Map);

        final user = User(
          id: userMap['id'] ?? '',
          email: userMap['email'] ?? '',
          name: userMap['name'] ?? '',
        );

        await MyPrefs.saveSession(authToken: token, user: user);

        return true;
      } else {
        log('$_tag login failed -> ${response.data}');
        return false;
      }
    } catch (e) {
      log('$_tag login error -> $e');
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      log('$_tag register -> ${ApiConstants.signUp}');

      final response = await _dio.post(
        ApiConstants.signUp,
        data: {'email': email, 'password': password, 'name': name},
      );

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final token = data['access_token']?.toString() ?? '';
        final userMap = Map<String, dynamic>.from(data['user'] as Map);

        final user = User(
          id: userMap['id'] ?? '',
          email: userMap['email'] ?? '',
          name: userMap['name'] ?? '',
        );

        await MyPrefs.saveSession(authToken: token, user: user);

        return true;
      } else {
        log('$_tag register failed -> ${response.data}');
        return false;
      }
    } catch (e) {
      log('$_tag register error -> $e');
      return false;
    }
  }

  void logout() {
    MyPrefs.clearSession();
  }

  bool get isLoggedIn => MyPrefs.getAuthToken() != null;
}
