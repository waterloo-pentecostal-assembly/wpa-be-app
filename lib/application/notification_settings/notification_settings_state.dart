part of 'notification_settings_bloc.dart';

abstract class NotificationSettingsState extends Equatable {
  const NotificationSettingsState();
  
  @override
  List<Object> get props => [];
}

class NotificationSettingsInitial extends NotificationSettingsState {}
