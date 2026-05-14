import 'dart:convert';

import 'package:chat_bot_app/constants/my_pref_constants.dart';
import 'package:chat_bot_app/model/app_models.dart';
import 'package:chat_bot_app/utils/globals.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class MyPrefs {
  static final _storage = GetStorage();

  MyPrefs._();

  static Future<void> init() async {
    await GetStorage.init();
  }

  static Future<void> saveSession({
    String? token,
    User? user,
    String? authToken,
  }) async {
    if (token != null) {
      await _storage.write(MyPrefConstant.currentUserToken, token);
    }
    if (user != null) {
      await _storage.write(
        MyPrefConstant.currentUser,
        jsonEncode(user.toJson()),
      );
    }
    if (authToken != null) {
      await _storage.write(MyPrefConstant.currentUserAuthToken, authToken);
    }
  }

  static String? getAuthToken() =>
      _storage.read(MyPrefConstant.currentUserAuthToken);

  static String? getUserToken() =>
      _storage.read(MyPrefConstant.currentUserToken);

  static String? getFcmToken() => _storage.read(MyPrefConstant.fcmToken);

  static Future<void> saveFcmToken(String token) async {
    await _storage.write(MyPrefConstant.fcmToken, token);
  }

  static User? getUser() {
    final savedValue = _storage.read(MyPrefConstant.currentUser);
    if (savedValue != null) {
      if (savedValue is String) {
        return User.fromJson(
          Map<String, dynamic>.from(jsonDecode(savedValue) as Map),
        );
      }
      if (savedValue is Map) {
        return User.fromJson(Map<String, dynamic>.from(savedValue));
      }
    }
    return null;
  }

  static int getAppLaunchCounter() {
    return (_storage.read(MyPrefConstant.appLaunchCounter) as int?) ?? 0;
  }

  static Future<void> incrementAppLaunchCounter() async {
    final currentCount =
        (_storage.read(MyPrefConstant.appLaunchCounter) as int?) ?? 0;

    await _storage.write(MyPrefConstant.appLaunchCounter, currentCount + 1);
  }

  static Future<void> clearSession() async {
    currentUserListenable.value = null;
    await _storage.remove(MyPrefConstant.currentUser);
    await _storage.remove(MyPrefConstant.currentUserToken);
    await _storage.remove(MyPrefConstant.currentUserAuthToken);
    await _storage.remove(MyPrefConstant.notificationCount);
    await _storage.remove(MyPrefConstant.fcmToken);
    await _storage.remove(MyPrefConstant.conversationId);
  }

  static int getNotificationCount() {
    return (_storage.read(MyPrefConstant.notificationCount) as int?) ?? 0;
  }

  static Future<void> saveNotificationCount(int count) async {
    await _storage.write(MyPrefConstant.notificationCount, count);
  }

  static Future<void> setConversationId(String conversationId) async {
    await _storage.write(MyPrefConstant.conversationId, conversationId);
  }

  static String? getConversationId() {
    return _storage.read(MyPrefConstant.conversationId)?.toString();
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    await _storage.write(MyPrefConstant.themeMode, mode.name);
  }

  static ThemeMode getThemeMode() {
    final value = _storage.read(MyPrefConstant.themeMode)?.toString();
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}
