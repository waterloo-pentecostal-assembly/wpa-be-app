import 'package:flutter/material.dart';
import 'package:wpa_app/domain/common/exceptions.dart';

enum AuthenticationExceptionCode {
  INVALID_EMAIL_OR_PASSWORD,
  USER_NOT_FOUND,
  USER_DISABLED,
  EMAIL_NOT_VERIFIED,
  AUTHENTICATION_SERVER_ERROR,
  NOT_AUTHENTICATED,
}

/// Implements [BaseException] to provide an exception type specific to Authentication.
class AuthenticationException implements BaseException {
  /// Creates an [AuthenticationException] with the specified error [type],
  /// [message], and optional error [details].
  AuthenticationException({
    @required this.code,
    @required this.message,
    this.details,
  });

  /// An authentication exception type.
  final AuthenticationExceptionCode code;

  /// A human-readable error message. Should be able to safely display this to the user.
  final String message;

  /// Error details, possibly null.
  final dynamic details;
}
