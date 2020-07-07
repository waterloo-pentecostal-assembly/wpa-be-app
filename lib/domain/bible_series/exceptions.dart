class BibleSeriesException implements Exception {
  final String message;

  BibleSeriesException(this.message);
}

class MissingKeyException implements Exception {
  final String message;

  MissingKeyException(this.message);
}


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