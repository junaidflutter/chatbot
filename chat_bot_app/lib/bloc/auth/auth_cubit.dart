import 'package:chat_bot_app/services/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthStatus { initial, loading, success, failure }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService = AuthService();

  AuthCubit() : super(const AuthState());

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final success = await _authService.login(email, password);
    if (success) {
      emit(state.copyWith(status: AuthStatus.success));
    } else {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Login failed. Please check your credentials.',
      ));
    }
  }

  Future<void> register(String email, String password, String name) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final success = await _authService.register(email, password, name);
    if (success) {
      emit(state.copyWith(status: AuthStatus.success));
    } else {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Registration failed.',
      ));
    }
  }

  void logout() {
    _authService.logout();
    emit(const AuthState());
  }
}
