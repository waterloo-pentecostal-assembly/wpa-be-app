import 'package:flutter/material.dart';

enum ApplicationExceptionType {
  PERMISSION_DENIED,
  MISSING_KEY,
  VALUE_OBJECT,
  UNKNOWN,
}

class ApplicationException implements Exception {
  final String message;
  final ApplicationExceptionType errorType;
  String displayMessage;

  ApplicationException({@required this.message, @required this.errorType, this.displayMessage}) {
    if (displayMessage == null) {
      this.displayMessage = this.message;
    }
  }

  @override
  String toString() {
    return '${this.runtimeType}: [${this.errorType}] ${this.message}';
  }
}