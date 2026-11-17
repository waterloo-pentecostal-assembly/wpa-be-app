import '../common/exceptions.dart';

enum NotificationSettingsExceptionCode {
  unableToSubscribe,
  unableToUnsubscribe,
  noNotificationSettings,
}

class NotificationSettingsException
    extends BaseApplicationException<NotificationSettingsExceptionCode> {
  const NotificationSettingsException({
    required super.code,
    required super.message,
    super.details,
  });
}
