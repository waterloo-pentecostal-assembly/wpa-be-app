
import '../common/exceptions.dart';

enum UserProfileExceptionCode { UNABLE_TO_UPLOAD_IMAGE, UNKNOWN }

/// Implements [BaseException] to provide an exception type specific to User Profile.
class UserProfileException implements BaseApplicationException {
  /// Creates an [PrayerRequestsException] with the specified error [type],
  /// [message], and optional error [details].
  UserProfileException({
    required this.code,
    required this.message,
    this.details,
  });

  /// An authentication exception type.
  final UserProfileExceptionCode code;

  /// A human-readable error message. Should be able to safely display this to the user.
  final String message;

  /// Error details, possibly null.
  final dynamic details;
}
