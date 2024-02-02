import '../common/exceptions.dart';

enum PrayerRequestsExceptionCode {
  NO_STARTING_DOCUMENT,
  PRAYER_REQUEST_NOT_FOUND,
  ALREADY_REPORTED,
}

/// Implements [BaseException] to provide an exception type specific to Bible Series.
class PrayerRequestsException implements BaseApplicationException {
  /// Creates an [PrayerRequestsException] with the specified error [type],
  /// [message], and optional error [details].
  PrayerRequestsException({
    required this.code,
    required this.message,
    this.details,
  });

  /// An authentication exception type.
  final PrayerRequestsExceptionCode code;

  /// A human-readable error message. Should be able to safely display this to the user.
  final String message;

  /// Error details, possibly null.
  final dynamic details;
}
