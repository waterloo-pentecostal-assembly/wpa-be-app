/// File that hold all constant values used by the app. Equivalent to environment variables.abstract

class _AppConstants {
  // Minimum eight characters, at least one letter and one number:
  String get passwordRegex => r"""^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$""";

  String get emailRegex => r"""^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";

  // In number of characters
  int get maxResponseBody => 4000;
}

// ignore: non_constant_identifier_names
_AppConstants AppConstants = _AppConstants();
