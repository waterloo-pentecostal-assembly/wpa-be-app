import 'package:flutter/material.dart';

enum AuthenticationExceptionType {
  INVALID_EMAIL_OR_PASSWORD,
  USER_NOT_FOUND,
  USER_DISABLED,
  EMAIL_NOT_VERIFIED,
  AUTHENTICATION_SERVER_ERROR,
  NOT_AUTHENTICATED,
}

class AuthenticationException implements Exception {
  final AuthenticationExceptionType errorType;
  final String message;
  String displayMessage;

  AuthenticationException({@required this.errorType, @required this.message, this.displayMessage}) {
    if (displayMessage == null) {
      this.displayMessage = this.message;
    }
  }

  @override
  String toString() {
    return '${this.runtimeType}: [${this.errorType}] ${this.message}';
  }
}
