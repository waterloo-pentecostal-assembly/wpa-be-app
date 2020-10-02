import 'package:flutter/material.dart';


// class ApplicationException implements Exception {
//   final String message;
//   final ApplicationExceptionType errorType;
//   String displayMessage;

//   ApplicationException({@required this.message, @required this.errorType, this.displayMessage}) {
//     if (displayMessage == null) {
//       this.displayMessage = this.message;
//     }
//   }

//   @override
//   String toString() {
//     return '${this.runtimeType}: [${this.errorType}] ${this.message}';
//   }
// }

/// Parent exception of all exceptions thrown in the app.
/// Any specific exception type must implement this class.
abstract class BaseException implements Exception {
  /// An application exception type. This should be of type [enum].
  final dynamic code;

  /// A human-readable error message. Should be able to safely display this to the user.
  final String message;

  /// Error details, possibly null.
  final dynamic details;

  /// Creates a [BaseException] with the specified error [type],
  /// [message], and optional error [details].
  BaseException({
    @required this.code,
    @required this.message,
    this.details,
  });

  @override
  String toString() => "[${this.runtimeType}: $code] $message $details";
}

enum ValueObjectExceptionCode {
  INVALID_FORMAT,
  
}

/// Implements [BaseException] to provide an exception type specific to Value Objects.
class ValueObjectException implements BaseException {
  final ValueObjectExceptionCode code;
  final String message;
  final dynamic details;

  /// Creates a [ValueObjectException] with the specified error [type],
  /// [message], and optional error [details].
  ValueObjectException({
    this.code = ValueObjectExceptionCode.VALUE_OBJECT,
    @required this.message,
    this.details,
  });
}


enum ApplicationExceptionCode {
  PERMISSION_DENIED,
  MISSING_KEY,
  UNKNOWN,
}

/// Implements [BaseException] to provide an exception type for Application level errors.
class ApplicationException implements BaseException {
  final ApplicationExceptionCode code;
  final String message;
  final dynamic details;

  /// Creates a [ApplicationException] with the specified error [type],
  /// [message], and optional error [details].
  ApplicationException({
    @required this.code,
    @required this.message,
    this.details,
  });
}
