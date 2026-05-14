import 'package:chat_bot_app/utils/my_pref.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;

  const ThemeState(this.themeMode);

  const ThemeState.initial() : this(ThemeMode.system);

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode ?? this.themeMode);
  }

  @override
  List<Object?> get props => [themeMode];
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState.initial());

  Future<void> bootstrap() async {
    emit(ThemeState(MyPrefs.getThemeMode()));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await MyPrefs.setThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> toggleTheme() async {
    final next =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}
