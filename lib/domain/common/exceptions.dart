class UnexpectedError implements Exception {
  final String message;

  UnexpectedError(this.message);
}

class ValueObjectException implements Exception {
  final String message;

  ValueObjectException(this.message);
}