import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Themes {
  static const String _fontFamily = 'Inter';

  ThemeData selectLightTheme() {
    final Map<int, Color> color = {
      50: ColorName.primaryColor.withValues(alpha: 0.1),
      100: ColorName.primaryColor.withValues(alpha: 0.2),
      200: ColorName.primaryColor.withValues(alpha: 0.3),
      300: ColorName.primaryColor.withValues(alpha: 0.4),
      400: ColorName.primaryColor.withValues(alpha: 0.5),
      500: ColorName.primaryColor.withValues(alpha: 0.6),
      600: ColorName.primaryColor.withValues(alpha: 0.7),
      700: ColorName.primaryColor.withValues(alpha: 0.8),
      800: ColorName.primaryColor.withValues(alpha: 0.9),
      900: ColorName.primaryColor.withValues(alpha: 1.0),
    };

    return ThemeData(
      useMaterial3: false,
      fontFamily: _fontFamily,
      brightness: Brightness.light,
      primaryColor: ColorName.primaryColor,
      scaffoldBackgroundColor: Colors.white,
      primarySwatch: MaterialColor(ColorName.primaryColor.toARGB32(), color),
      splashColor: ColorName.primaryColor.withValues(alpha: 0.2),
      textTheme: selectTextTheme(),
      appBarTheme: selectAppBarTheme(),
      elevatedButtonTheme: elevatedButtonTheme(),
      outlinedButtonTheme: outLinedButtonTheme(),
      inputDecorationTheme: inputDecorationTheme(),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(ColorName.primaryColor),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.withAlpha(50)),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: const ListTileThemeData(tileColor: Colors.white),
    );
  }

  ThemeData selectDarkTheme() {
    final Map<int, Color> color = {
      50: ColorName.purple.withValues(alpha: 0.1),
      100: ColorName.purple.withValues(alpha: 0.2),
      200: ColorName.purple.withValues(alpha: 0.3),
      300: ColorName.purple.withValues(alpha: 0.4),
      400: ColorName.purple.withValues(alpha: 0.5),
      500: ColorName.purple.withValues(alpha: 0.6),
      600: ColorName.purple.withValues(alpha: 0.7),
      700: ColorName.purple.withValues(alpha: 0.8),
      800: ColorName.purple.withValues(alpha: 0.9),
      900: ColorName.purple.withValues(alpha: 1.0),
    };

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: Brightness.dark,
      primaryColor: ColorName.purple,
      scaffoldBackgroundColor: const Color(0xFF0F1118),
      primarySwatch: MaterialColor(ColorName.purple.toARGB32(), color),
      splashColor: ColorName.purple.withValues(alpha: 0.2),
      textTheme: selectDarkTextTheme(),
      appBarTheme: selectDarkAppBarTheme(),
      elevatedButtonTheme: elevatedButtonTheme(),
      outlinedButtonTheme: outLinedButtonTheme(),
      inputDecorationTheme: darkInputDecorationTheme(),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(ColorName.purple),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withAlpha(30)),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: const ListTileThemeData(tileColor: Color(0xFF171A22)),
    );
  }

  TextTheme selectTextTheme() {
    return const TextTheme(
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      displayLarge: TextStyle(
        fontSize: 32,
        color: Colors.black,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: TextStyle(
        fontSize: 30,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        color: Colors.black,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        color: Colors.black,
        fontWeight: FontWeight.w400,
      ),
      bodyLarge: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.black,
        fontWeight: FontWeight.w400,
      ),
      titleMedium: TextStyle(
        fontSize: 12,
        color: Colors.black,
        fontWeight: FontWeight.w400,
      ),
      titleSmall: TextStyle(
        color: Colors.black,
        fontSize: 10,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  AppBarTheme selectAppBarTheme() {
    return const AppBarTheme(
      iconTheme: IconThemeData(color: Colors.black),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: ColorName.primaryColor,
      ),
    );
  }

  TextTheme selectDarkTextTheme() {
    return const TextTheme(
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      displayLarge: TextStyle(
        fontSize: 32,
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: TextStyle(
        fontSize: 30,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        color: Colors.white,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.w400,
      ),
      bodyLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w400,
      ),
      titleMedium: TextStyle(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.w400,
      ),
      titleSmall: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  AppBarTheme selectDarkAppBarTheme() {
    return const AppBarTheme(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Color(0xFF0F1118),
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: ColorName.purple,
      ),
    );
  }

  ElevatedButtonThemeData elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
        disabledForegroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
        backgroundColor: ColorName.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  OutlinedButtonThemeData outLinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecorationTheme inputDecorationTheme() {
    return InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: const BorderSide(color: ColorName.primaryColor),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0)),
      focusColor: ColorName.primaryColor,
      hintStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      fillColor: Colors.white,
      filled: true,
    );
  }

  InputDecorationTheme darkInputDecorationTheme() {
    return InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: const BorderSide(color: ColorName.purple),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusColor: ColorName.purple,
      hintStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      fillColor: const Color(0xFF171A22),
      filled: true,
    );
  }
}
