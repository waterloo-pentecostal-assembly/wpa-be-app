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
    on<SubscribedToForumCommentReplies>(_onSubscribedToForumCommentReplies);
    on<UnsubscribedFromForumCommentReplies>(
        _onUnsubscribedFromForumCommentReplies);
    on<SubscribedToForumCommentLikes>(_onSubscribedToForumCommentLikes);
    on<UnsubscribedFromForumCommentLikes>(_onUnsubscribedFromForumCommentLikes);
    on<SubscribedToForumThreadComments>(_onSubscribedToForumThreadComments);
    on<UnsubscribedFromForumThreadComments>(
        _onUnsubscribedFromForumThreadComments);
    on<ThreadFollowed>(_onThreadFollowed);
    on<ThreadUnfollowed>(_onThreadUnfollowed);
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

  Future<void> _onSubscribedToForumCommentReplies(
    SubscribedToForumCommentReplies event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.subscribeToForumCommentReplies();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to subscribe"));
    }
  }

  Future<void> _onUnsubscribedFromForumCommentReplies(
    UnsubscribedFromForumCommentReplies event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.unsubscribeFromForumCommentReplies();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to unsubscribe"));
    }
  }

  Future<void> _onSubscribedToForumCommentLikes(
    SubscribedToForumCommentLikes event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.subscribeToForumCommentLikes();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to subscribe"));
    }
  }

  Future<void> _onUnsubscribedFromForumCommentLikes(
    UnsubscribedFromForumCommentLikes event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.unsubscribeFromForumCommentLikes();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to unsubscribe"));
    }
  }

  Future<void> _onSubscribedToForumThreadComments(
    SubscribedToForumThreadComments event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.subscribeToForumThreadComments();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to subscribe"));
    }
  }

  Future<void> _onUnsubscribedFromForumThreadComments(
    UnsubscribedFromForumThreadComments event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      await _iNotificationSettingsService.unsubscribeFromForumThreadComments();
    } catch (e) {
      emit(NotificationSettingsError(message: "Unable to unsubscribe"));
    }
  }

  Future<void> _onThreadFollowed(
    ThreadFollowed event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final currentSettings = currentState.notificationSettings;
      final updatedList = List<String>.from(currentSettings.threadsFollowed)
        ..add(event.threadId);
      final updatedSettings =
          currentSettings.copyWith(threadsFollowed: updatedList);

      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));

      try {
        await _iNotificationSettingsService.followThread(event.threadId);
      } catch (e) {
        emit(currentState);
        emit(NotificationSettingsError(message: "Unable to follow thread"));
      }
    } else {
      try {
        await _iNotificationSettingsService.followThread(event.threadId);
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(NotificationSettingsError(message: "Unable to follow thread"));
      }
    }
  }

  Future<void> _onThreadUnfollowed(
    ThreadUnfollowed event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final currentSettings = currentState.notificationSettings;
      final updatedList = List<String>.from(currentSettings.threadsFollowed)
        ..remove(event.threadId);
      final updatedSettings =
          currentSettings.copyWith(threadsFollowed: updatedList);

      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));

      try {
        await _iNotificationSettingsService.unfollowThread(event.threadId);
      } catch (e) {
        emit(currentState);
        emit(NotificationSettingsError(message: "Unable to unfollow thread"));
      }
    } else {
      try {
        await _iNotificationSettingsService.unfollowThread(event.threadId);
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(NotificationSettingsError(message: "Unable to unfollow thread"));
      }
    }
  }
}
