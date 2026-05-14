import 'dart:convert';
import 'dart:developer';

import 'package:chat_bot_app/constants/api_constants.dart';
import 'package:chat_bot_app/model/app_models.dart';
import 'package:chat_bot_app/utils/my_pref.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _tag = '[AuthService]';

  Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse('${ApiConstants.devUrl}/auth/login');
      log('$_tag login -> $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      log('$_tag login response -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        final userMap = data['user'] as Map<String, dynamic>;

        final user = User(
          id: userMap['id'] ?? '',
          email: userMap['email'] ?? '',
          name: userMap['name'] ?? '',
        );

        await MyPrefs.saveSession(authToken: token, user: user);

        return true;
      } else {
        log('$_tag login failed -> ${response.body}');
        return false;
      }
    } catch (e) {
      log('$_tag login error -> $e');
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      final url = Uri.parse('${ApiConstants.devUrl}/auth/register');
      log('$_tag register -> $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        final userMap = data['user'] as Map<String, dynamic>;

        final user = User(
          id: userMap['id'] ?? '',
          email: userMap['email'] ?? '',
          name: userMap['name'] ?? '',
        );

        await MyPrefs.saveSession(authToken: token, user: user);

        return true;
      } else {
        log('$_tag register failed -> ${response.body}');
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
