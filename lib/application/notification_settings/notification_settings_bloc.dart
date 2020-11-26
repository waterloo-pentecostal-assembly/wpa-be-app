import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/domain/notification_settings/entities.dart';

import '../../domain/notification_settings/interfaces.dart';

part 'notification_settings_event.dart';
part 'notification_settings_state.dart';

class NotificationSettingsBloc extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  final INotificationSettingsService _iNotificationSettingsService;

  NotificationSettingsBloc(this._iNotificationSettingsService) : super(NotificationSettingsInitial());

  @override
  Stream<NotificationSettingsState> mapEventToState(
    NotificationSettingsEvent event,
  ) async* {
    if (event is NotificationSettingsRequested) {
      yield* _mapNotificationSettingsRequestedToState(_iNotificationSettingsService);
    } else if (event is SubscribedToDailyEngagementReminder) {
      yield* _mapSubscribedToDailyEngagementReminderToState(_iNotificationSettingsService);
    } else if (event is UnsubscribedFromDailyEngagementReminder) {
      yield* _mapUnsubscribedFromDailyEngagementReminderToState(_iNotificationSettingsService);
    }else if (event is SubscribedToPrayerNotifications) {
      yield* _mapSubscribedToPrayerNotificationsToState(_iNotificationSettingsService);
    } else if (event is UnsubscribedFromPrayerNotifications) {
      yield* _mapUnsubscribedFromPrayerNotificationsToState(_iNotificationSettingsService);
    }
  }
}

Stream<NotificationSettingsState> _mapNotificationSettingsRequestedToState(
  INotificationSettingsService notificationSettingsService,
) async* {
  try {
    NotificationSettingsEntity notificationSettings = await notificationSettingsService.getNotificationSettings();
    yield NotificationSettingsPositions(notificationSettings: notificationSettings);
  } catch (e) {
    yield NotificationSettingsError(message: "Error loading notification settings");
  }
}

Stream<NotificationSettingsState> _mapSubscribedToDailyEngagementReminderToState(
  INotificationSettingsService notificationSettingsService,
) async* {
  try {
    await notificationSettingsService.subscribeToDailyEngagementReminder();
  } catch (e) {
    yield DailyEngagementReminderError(message: "Unable to subscribe");
  }
}

Stream<NotificationSettingsState> _mapUnsubscribedFromDailyEngagementReminderToState(
  INotificationSettingsService notificationSettingsService,
) async* {
  try {
    await notificationSettingsService.unsubscribeFromDailyEngagementReminder();
  } catch (e) {
    yield DailyEngagementReminderError(message: "Unable to unsubscribe");
  }
}

Stream<NotificationSettingsState> _mapSubscribedToPrayerNotificationsToState(
  INotificationSettingsService notificationSettingsService,
) async* {
  try {
    await notificationSettingsService.subscribeToPrayerNotifications();
  } catch (e) {
    yield PrayerNotificationError(message: "Unable to subscribe");
  }
}

Stream<NotificationSettingsState> _mapUnsubscribedFromPrayerNotificationsToState(
  INotificationSettingsService notificationSettingsService,
) async* {
  try {
    await notificationSettingsService.unsubscribeFromPrayerNotifications();
  } catch (e) {
    yield PrayerNotificationError(message: "Unable to unsubscribe");
  }
}
