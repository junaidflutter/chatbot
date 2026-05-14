import 'package:flutter/material.dart';

class TextFieldValidators {
  TextFieldValidators._();

  static String? emailFieldValidation(String? email) {
    if (email!.isEmpty ||
        !RegExp(
          r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
        ).hasMatch(email)) {
      return 'Enter correct email';
    }
    return null;
  }

  static String? passwordFieldValidator(String? password) {
    if (password?.isEmpty ?? true) {
      return 'This field is required';
    } else if (password!.length < 8) {
      return 'Password must be 8 or more';
    }
    return null;
  }

  static String? emptyFieldValidator(String? value, String message) {
    if (value?.isEmpty ?? true && value != null) {
      return message;
    }
    return null;
  }

  static String? nullFieldValidator(Object? value, String message) {
    if (value == null) {
      return message;
    }
    return null;
  }

  static String? minLengthValidator(
    String? value,
    int minLength,
    String errorMessage,
  ) {
    if (value != null && value.length >= minLength) {
      return null;
    }
    return errorMessage;
  }

  static String? passwordValidator(String? password) {
    if (password == null || password.trim().isEmpty) {
      return 'Please enter the password';
    } else if (password.length < 8) {
      return 'Password must have 8 or more characters';
    } else {
      return null;
    }
  }

  static String? confirmPasswordValidator(String? password) {
    if (password == null || password.trim().isEmpty) {
      return 'Please enter confirm password';
    } else if (password.length < 8) {
      return 'Confirm password must have 8 or more characters';
    } else {
      return null;
    }
  }

  static bool validateMobile(String phoneNumber) {
    final RegExp regex = RegExp(r'^\+\d{1,3}\d{9,12}$');
    return regex.hasMatch(phoneNumber);
  }

  static String? listValidateChecker(List<TextEditingController> controllers) {
    for (var i = 0; i < controllers.length; i++) {
      if (controllers[i].text.isNotEmpty) {
        return null; // No need for validation
      }
    }
    return 'Required';
  }
}
