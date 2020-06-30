class AuthenticationException implements Exception {
  final String message;

  AuthenticationException(this.message);
}

class NotAuthenticatedException implements Exception {}

class InvalidEmailOrPassword implements Exception {}

class UserNotFound implements Exception {}

class UserDisabled implements Exception {}

class AuthenticationServerError implements Exception {}
