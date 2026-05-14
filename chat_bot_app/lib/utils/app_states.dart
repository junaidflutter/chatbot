import 'package:chat_bot_app/utils/app_enums.dart';
import 'package:equatable/equatable.dart';

abstract class AppState extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

// Initial state
class Initial<T> extends AppState {
  const Initial();
}

// Loading state
class LoadingState<T> extends AppState {
  const LoadingState();
}

class VerificationRequiredState<T> extends AppState {
  final String email;
  const VerificationRequiredState(this.email);
}

class ResendCodeState<T> extends AppState {
  final T? data;

  const ResendCodeState({this.data});
}

// Success state
class SuccessState<T> extends AppState {
  final T? data;
  final SuccessStateType? type;

  const SuccessState({this.data, this.type});

  @override
  List<Object?> get props => [data, type];
}

// Failure state
class FailureState<T> extends AppState {
  final String message;
  const FailureState(this.message);

  @override
  List<Object?> get props => [message];
}

// RememberMe state
class RememberMeState extends AppState {
  final bool rememberMe;

  const RememberMeState({this.rememberMe = false});

  RememberMeState toggle() => RememberMeState(rememberMe: !rememberMe);

  @override
  List<Object?> get props => [rememberMe];
}

class AgreementCheckedState extends AppState {
  final bool isAccepted;

  const AgreementCheckedState({this.isAccepted = false});

  AgreementCheckedState toggle() =>
      AgreementCheckedState(isAccepted: !isAccepted);

  @override
  List<Object?> get props => [isAccepted];
}

// Terms & Conditions check state
class TermsCheckedState extends AppState {
  final bool isAccepted;

  const TermsCheckedState(this.isAccepted);

  @override
  List<Object?> get props => [isAccepted];
}
