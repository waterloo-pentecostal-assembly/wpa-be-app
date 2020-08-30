class AuthenticationException implements Exception {
  String message;
  String displayMessage;

  AuthenticationException({this.message, this.displayMessage}) {
    if (displayMessage == null) {
      this.displayMessage = 'Invalid email or password.';
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

class NotAuthenticatedException implements Exception {}

class InvalidEmailOrPassword implements Exception {
  String message;
  String displayMessage;

  InvalidEmailOrPassword({this.message, this.displayMessage}) {
    if (displayMessage == null) {
      this.displayMessage = 'Invalid email or password.';
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

class UserNotFound implements Exception {
  String message;
  String displayMessage;

  UserNotFound({this.message, this.displayMessage}) {
    if (displayMessage == null) {
      this.displayMessage = 'User not found, please sign up.';
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

class UserDisabled implements Exception {
  String message;
  String displayMessage;

  UserDisabled({this.message, this.displayMessage}) {
    if (displayMessage == null) {
      this.displayMessage = 'User disabled.';
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

class AuthenticationServerError implements Exception {
  String message;
  String displayMessage;

  AuthenticationServerError({this.message, this.displayMessage}) {
    if (displayMessage == null) {
      this.displayMessage = 'Authentication Server error. Please try again later.';
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
