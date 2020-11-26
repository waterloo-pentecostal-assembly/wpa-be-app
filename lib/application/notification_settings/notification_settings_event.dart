part of 'notification_settings_bloc.dart';

abstract class NotificationSettingsEvent extends Equatable {
  const NotificationSettingsEvent();

  @override
  List<Object> get props => [];
}

class NotificationSettingsRequested extends NotificationSettingsEvent {
  NotificationSettingsRequested();

  @override
  List<Object> get props => [];
}

class SubscribedToDailyEngagementReminder extends NotificationSettingsEvent {
  SubscribedToDailyEngagementReminder();

  @override
  List<Object> get props => [];
}

class UnsubscribedFromDailyEngagementReminder extends NotificationSettingsEvent {
  UnsubscribedFromDailyEngagementReminder();

  @override
  List<Object> get props => [];
}

class SubscribedToPrayerNotifications extends NotificationSettingsEvent {
  SubscribedToPrayerNotifications();

  @override
  List<Object> get props => [];
}

class UnsubscribedFromPrayerNotifications extends NotificationSettingsEvent {
  UnsubscribedFromPrayerNotifications();

  @override
  List<Object> get props => [];
}
