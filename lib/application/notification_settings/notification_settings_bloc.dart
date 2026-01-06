import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wpa_app/domain/notification_settings/entities.dart';

import '../../domain/notification_settings/interfaces.dart';

part 'notification_settings_event.dart';
part 'notification_settings_state.dart';

class NotificationSettingsBloc
    extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  final INotificationSettingsService _iNotificationSettingsService;

  NotificationSettingsBloc(this._iNotificationSettingsService)
      : super(NotificationSettingsInitial()) {
    on<NotificationSettingsRequested>(_onNotificationSettingsRequested);
    on<SubscribedToDailyEngagementReminder>(
        _onSubscribedToDailyEngagementReminder);
    on<UnsubscribedFromDailyEngagementReminder>(
        _onUnsubscribedFromDailyEngagementReminder);
    on<SubscribedToPrayerNotifications>(_onSubscribedToPrayerNotifications);
    on<UnsubscribedFromPrayerNotifications>(
        _onUnsubscribedFromPrayerNotifications);
    on<SubscribedToTestimonyNotifications>(
        _onSubscribedToTestimonyNotifications);
    on<UnsubscribedFromTestimonyNotifications>(
        _onUnsubscribedFromTestimonyNotifications);
    on<SubscribedToForumThreads>(_onSubscribedToForumThreads);
    on<UnsubscribedFromForumThreads>(_onUnsubscribedFromForumThreads);
    on<SubscribedToForumComments>(_onSubscribedToForumComments);
    on<UnsubscribedFromForumComments>(_onUnsubscribedFromForumComments);
    on<SubscribedToForumLikes>(_onSubscribedToForumLikes);
    on<UnsubscribedFromForumLikes>(_onUnsubscribedFromForumLikes);
  }

  Future<void> _onNotificationSettingsRequested(
    NotificationSettingsRequested event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      NotificationSettingsEntity notificationSettings =
          await _iNotificationSettingsService.getNotificationSettings();
      emit(NotificationSettingsPositions(
          notificationSettings: notificationSettings));
    } catch (e) {
      emit(NotificationSettingsError(
          message: "Error loading notification settings"));
    }
  }

  Future<void> _onSubscribedToDailyEngagementReminder(
    SubscribedToDailyEngagementReminder event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.subscribeToDailyEngagementReminder();
    } catch (e) {
      emit(DailyEngagementReminderError(message: "Unable to subscribe"));
    }
  }

  Future<void> _onUnsubscribedFromDailyEngagementReminder(
    UnsubscribedFromDailyEngagementReminder event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService
          .unsubscribeFromDailyEngagementReminder();
    } catch (e) {
      emit(DailyEngagementReminderError(message: "Unable to unsubscribe"));
    }
  }

  Future<void> _onSubscribedToPrayerNotifications(
    SubscribedToPrayerNotifications event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.subscribeToPrayerNotifications();
    } catch (e) {
      emit(PrayerNotificationError(message: "Unable to subscribe"));
    }
  }

  Future<void> _onUnsubscribedFromPrayerNotifications(
    UnsubscribedFromPrayerNotifications event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.unsubscribeFromPrayerNotifications();
    } catch (e) {
      emit(PrayerNotificationError(message: "Unable to unsubscribe"));
    }
  }

  Future<void> _onSubscribedToTestimonyNotifications(
    SubscribedToTestimonyNotifications event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.subscribeToTestimonyNotifications();
    } catch (e) {
      emit(TestimonyNotificationError(message: "Unable to subscribe"));
    }
  }

  Future<void> _onUnsubscribedFromTestimonyNotifications(
    UnsubscribedFromTestimonyNotifications event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService
          .unsubscribeFromTestimonyNotifications();
    } catch (e) {
      emit(TestimonyNotificationError(message: "Unable to unsubscribe"));
    }
  }

  Future<void> _onSubscribedToForumThreads(
    SubscribedToForumThreads event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.subscribeToForumThreads();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to subscribe"));
    }
  }

  Future<void> _onUnsubscribedFromForumThreads(
    UnsubscribedFromForumThreads event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.unsubscribeFromForumThreads();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to unsubscribe"));
    }
  }

  Future<void> _onSubscribedToForumComments(
    SubscribedToForumComments event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.subscribeToForumComments();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to subscribe"));
    }
  }

  Future<void> _onUnsubscribedFromForumComments(
    UnsubscribedFromForumComments event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.unsubscribeFromForumComments();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to unsubscribe"));
    }
  }

  Future<void> _onSubscribedToForumLikes(
    SubscribedToForumLikes event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.subscribeToForumLikes();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to subscribe"));
    }
  }

  Future<void> _onUnsubscribedFromForumLikes(
    UnsubscribedFromForumLikes event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.unsubscribeFromForumLikes();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to unsubscribe"));
    }
  }
}
