import 'package:chat_bot_app/bloc/theme/theme_cubit.dart';
import 'package:chat_bot_app/screens/login_screen.dart';
import 'package:chat_bot_app/screens/main_shell.dart';
import 'package:chat_bot_app/utils/app_theme.dart';
import 'package:chat_bot_app/utils/my_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MyPrefs.init();
  runApp(const ChatBotApp());
}

class ChatBotApp extends StatelessWidget {
  const ChatBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themes = Themes();

    return BlocProvider(
      create: (_) => ThemeCubit()..bootstrap(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final lightTheme = themes.selectLightTheme();
          final darkTheme = themes.selectDarkTheme();
          final themeMode = state.themeMode;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Chat Bot',
            theme: lightTheme.copyWith(
              colorScheme: lightTheme.colorScheme.copyWith(
                primary: lightTheme.primaryColor,
                secondary: lightTheme.primaryColor,
                surface: lightTheme.scaffoldBackgroundColor,
              ),
            ),
            darkTheme: darkTheme.copyWith(
              colorScheme: darkTheme.colorScheme.copyWith(
                primary: darkTheme.primaryColor,
                secondary: darkTheme.primaryColor,
                surface: darkTheme.scaffoldBackgroundColor,
              ),
            ),
            themeMode: themeMode,
            home: MyPrefs.getAuthToken() != null
                ? const MainShell()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
