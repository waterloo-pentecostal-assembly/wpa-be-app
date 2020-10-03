import 'package:flutter/material.dart';

/// Parent exception of all exceptions thrown in the app.
/// Any specific exception type must implement this class.
abstract class BaseApplicationException implements Exception {
  /// An application exception type. This should be of type [enum].
  final dynamic code;

  /// A human-readable error message. Should be able to safely display this to the user.
  final String message;

  /// Error details, possibly null.
  final dynamic details;

  /// Creates a [BaseApplicationException] with the specified error [type],
  /// [message], and optional error [details].
  BaseApplicationException({
    @required this.code,
    @required this.message,
    this.details,
  });

  @override
  String toString() => "[${this.runtimeType}: $code] $message $details";
}

enum ValueObjectExceptionCode {
  INVALID_FORMAT,
  TOO_LONG,
  TOO_SHORT,
}

/// Implements [BaseApplicationException] to provide an exception type specific to Value Objects.
class ValueObjectException implements BaseApplicationException {
  final ValueObjectExceptionCode code;
  final String message;
  final dynamic details;

  /// Creates a [ValueObjectException] with the specified error [type],
  /// [message], and optional error [details]. Default code is 
  /// [ValueObjectExceptionCode.INVALID_FORMAT]
  ValueObjectException({
    this.code = ValueObjectExceptionCode.INVALID_FORMAT,
    @required this.message,
    this.details,
  });
}

enum ApplicationExceptionCode {
  PERMISSION_DENIED,
  MISSING_KEY,
  UNKNOWN,
}

/// Implements [BaseApplicationException] to provide an exception type for Application level errors.
class ApplicationException implements BaseApplicationException {
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
