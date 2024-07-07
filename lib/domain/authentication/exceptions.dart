import 'package:wpa_app/domain/common/exceptions.dart';

enum AuthenticationExceptionCode {
  INVALID_EMAIL_OR_PASSWORD,
  USER_NOT_FOUND,
  USER_COLLECTION_NOT_FOUND,
  USER_DISABLED,
  USER_NOT_VERIFIED,
  EMAIL_NOT_VERIFIED,
  AUTHENTICATION_SERVER_ERROR,
  NOT_AUTHENTICATED,
  EMAIL_IN_USE,
  REQUIRES_RECENT_LOGIN,
}

/// Implements [BaseException] to provide an exception type specific to Authentication.
class AuthenticationException implements BaseApplicationException {
  /// Creates an [AuthenticationException] with the specified error [type],
  /// [message], and optional error [details].
  AuthenticationException({
    required this.code,
    required this.message,
    this.details,
  });

  /// An authentication exception type.
  final AuthenticationExceptionCode code;

  /// A human-readable error message. Should be able to safely display this to the user.
  final String message;

  /// Error details, possibly null.
  final dynamic details;
}
