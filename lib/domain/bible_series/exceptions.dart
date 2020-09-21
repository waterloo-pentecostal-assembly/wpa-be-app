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

// class InvalidContentBodyType implements Exception {
//   final String message;
//   String displayMessage;

//   InvalidContentBodyType({@required this.message, this.displayMessage}) {
//     if (displayMessage == null) {
//       this.displayMessage = this.message;
//     }
//   }

//   @override
//   String toString() {
//     return '${this.runtimeType}: ${this.message}';
//   }
// }

// EXAMPLE
/*
class PlatformException implements Exception {
  /// Creates a [PlatformException] with the specified error [code] and optional
  /// [message], and with the optional error [details] which must be a valid
  /// value for the [MethodCodec] involved in the interaction.
  PlatformException({
    @required this.code,
    this.message,
    this.details,
  }) : assert(code != null);

  /// An error code.
  final String code;

  /// A human-readable error message, possibly null.
  final String message;

  /// Error details, possibly null.
  final dynamic details;

  @override
  String toString() => 'PlatformException($code, $message, $details)';
}
*/
