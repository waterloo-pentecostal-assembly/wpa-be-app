part of 'notification_settings_bloc.dart';

abstract class NotificationSettingsEvent extends Equatable {
  const NotificationSettingsEvent();

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