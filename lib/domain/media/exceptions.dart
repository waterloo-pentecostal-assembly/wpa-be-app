import '../common/exceptions.dart';

enum MediaExceptionCode {
  GENERIC,
}

/// Implements [BaseException] to provide an exception type specific to Media.
class MediaException implements BaseApplicationException {
  /// Creates an [PrayerRequestsException] with the specified error [type],
  /// [message], and optional error [details].
  MediaException({
    required this.code,
    required this.message,
    this.details,
  });

  /// An authentication exception type.
  @override
  final MediaExceptionCode code;

  /// A human-readable error message. Should be able to safely display this to the user.
  @override
  final String message;

  /// Error details, possibly null.
  @override
  final dynamic details;
}
