import 'package:chat_bot_app/model/app_models.dart';
import 'package:chat_bot_app/utils/my_pref.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<User?> currentUserListenable = ValueNotifier<User?>(
  MyPrefs.getUser(),
);
final ValueNotifier<bool?> isLoading = ValueNotifier<bool?>(false);
