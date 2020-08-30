import 'package:flutter/material.dart';

class UnexpectedError implements Exception {
  String message;
  String displayMessage;

  UnexpectedError({this.message, this.displayMessage}) {
    if (displayMessage == null) {
      this.displayMessage = 'An unexpected error occured.';
    }
    if (message == null) {
      this.message = this.displayMessage;
    }
  }

  @override
  String toString() {
    return '${this.runtimeType}: ${this.message}';
  }
}

class ValueObjectException implements Exception {
  final String message;
  String displayMessage;

  ValueObjectException({@required this.message, this.displayMessage}) {
    if (displayMessage == null) {
      this.displayMessage = this.message;
    }
  }

  @override
  String toString() {
    return '${this.runtimeType}: ${this.message}';
  }
}
