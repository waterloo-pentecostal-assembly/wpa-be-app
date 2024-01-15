import '../common/exceptions.dart';

enum NotificationSettingsExceptionCode {
  UNABLE_TO_SUBSCRIBE,
  UNABLE_TO_UNSUBSCRIBE,
  NO_NOTIFICATION_SETTINGS,
}

/// Implements [BaseException] to provide an exception type specific to Notiifcation Settings.
class NotificationSettingsException implements BaseApplicationException {
  /// Creates an [PrayerRequestsException] with the specified error [type],
  /// [message], and optional error [details].
  NotificationSettingsException({
    required this.code,
    required this.message,
    this.details,
  });

  /// An authentication exception type.
  final NotificationSettingsExceptionCode code;

  /// A human-readable error message. Should be able to safely display this to the user.
  final String message;

  /// Error details, possibly null.
  final dynamic details;
}
