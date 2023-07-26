part of 'notification_settings_bloc.dart';

abstract class NotificationSettingsState extends Equatable {
  const NotificationSettingsState();

  @override
  List<Object> get props => [];
}

class NotificationSettingsInitial extends NotificationSettingsState {}

class NotificationSettingsPositions extends NotificationSettingsState {
  final NotificationSettingsEntity notificationSettings;

  NotificationSettingsPositions({required this.notificationSettings});

  @override
  List<Object> get props => [notificationSettings];
}

class DailyEngagementReminderError extends NotificationSettingsState {
  final String message;

  const DailyEngagementReminderError({required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}

class PrayerNotificationError extends NotificationSettingsState {
  final String message;

  const PrayerNotificationError({required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}

class NotificationSettingsError extends NotificationSettingsState {
  final String message;

  const NotificationSettingsError({required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}
