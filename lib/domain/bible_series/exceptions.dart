import 'package:flutter/material.dart';

enum BibleSeriesExceptionType {
  NO_BIBLE_SERIES,
  NO_SERIES_CONTENT,
  INVALID_CONTENT_BODY,
}

class BibleSeriesException implements Exception {
  final String message;
  final BibleSeriesExceptionType errorType;
  String displayMessage;

  BibleSeriesException({@required this.message, @required this.errorType, this.displayMessage}) {
    if (displayMessage == null) {
      this.displayMessage = this.message;
    }
  }

  @override
  String toString() {
    return '${this.runtimeType}: [${this.errorType}] ${this.message}';
  }
}
