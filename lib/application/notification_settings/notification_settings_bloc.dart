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
    on<SubscribedToNewPrayerRequests>(_onSubscribedToNewPrayerRequests);
    on<UnsubscribedFromNewPrayerRequests>(_onUnsubscribedFromNewPrayerRequests);
    on<SubscribedToTestimonyNotifications>(
        _onSubscribedToTestimonyNotifications);
    on<UnsubscribedFromTestimonyNotifications>(
        _onUnsubscribedFromTestimonyNotifications);
    on<SubscribedToNewTestimonies>(_onSubscribedToNewTestimonies);
    on<UnsubscribedFromNewTestimonies>(_onUnsubscribedFromNewTestimonies);
    on<SubscribedToNewForumThreads>(_onSubscribedToNewForumThreads);
    on<UnsubscribedFromNewForumThreads>(_onUnsubscribedFromNewForumThreads);
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
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings = currentState.notificationSettings
          .copyWith(dailyEngagementReminder: true);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService
            .subscribeToDailyEngagementReminder();
      } catch (e) {
        emit(currentState);
        emit(DailyEngagementReminderError(message: "Unable to subscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService
            .subscribeToDailyEngagementReminder();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(DailyEngagementReminderError(message: "Unable to subscribe"));
      }
    }
  }

  Future<void> _onUnsubscribedFromDailyEngagementReminder(
    UnsubscribedFromDailyEngagementReminder event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings = currentState.notificationSettings
          .copyWith(dailyEngagementReminder: false);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService
            .unsubscribeFromDailyEngagementReminder();
      } catch (e) {
        emit(currentState);
        emit(DailyEngagementReminderError(message: "Unable to unsubscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService
            .unsubscribeFromDailyEngagementReminder();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(DailyEngagementReminderError(message: "Unable to unsubscribe"));
      }
    }
  }

  Future<void> _onSubscribedToPrayerNotifications(
    SubscribedToPrayerNotifications event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(prayers: true);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.subscribeToPrayerNotifications();
      } catch (e) {
        emit(currentState);
        emit(PrayerNotificationError(message: "Unable to subscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.subscribeToPrayerNotifications();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(PrayerNotificationError(message: "Unable to subscribe"));
      }
    }
  }

  Future<void> _onUnsubscribedFromPrayerNotifications(
    UnsubscribedFromPrayerNotifications event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(prayers: false);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService
            .unsubscribeFromPrayerNotifications();
      } catch (e) {
        emit(currentState);
        emit(PrayerNotificationError(message: "Unable to unsubscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService
            .unsubscribeFromPrayerNotifications();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(PrayerNotificationError(message: "Unable to unsubscribe"));
      }
    }
  }

  Future<void> _onSubscribedToNewPrayerRequests(
    SubscribedToNewPrayerRequests event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(newPrayerRequest: true);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.subscribeToNewPrayerRequests();
      } catch (e) {
        emit(currentState);
        emit(PrayerNotificationError(message: "Unable to subscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.subscribeToNewPrayerRequests();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(PrayerNotificationError(message: "Unable to subscribe"));
      }
    }
  }

  Future<void> _onUnsubscribedFromNewPrayerRequests(
    UnsubscribedFromNewPrayerRequests event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(newPrayerRequest: false);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.unsubscribeFromNewPrayerRequests();
      } catch (e) {
        emit(currentState);
        emit(PrayerNotificationError(message: "Unable to unsubscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.unsubscribeFromNewPrayerRequests();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(PrayerNotificationError(message: "Unable to unsubscribe"));
      }
    }
  }

  Future<void> _onSubscribedToTestimonyNotifications(
    SubscribedToTestimonyNotifications event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(testimonies: true);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.subscribeToTestimonyNotifications();
      } catch (e) {
        emit(currentState);
        emit(TestimonyNotificationError(message: "Unable to subscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.subscribeToTestimonyNotifications();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(TestimonyNotificationError(message: "Unable to subscribe"));
      }
    }
  }

  Future<void> _onUnsubscribedFromTestimonyNotifications(
    UnsubscribedFromTestimonyNotifications event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(testimonies: false);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService
            .unsubscribeFromTestimonyNotifications();
      } catch (e) {
        emit(currentState);
        emit(TestimonyNotificationError(message: "Unable to unsubscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService
            .unsubscribeFromTestimonyNotifications();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(TestimonyNotificationError(message: "Unable to unsubscribe"));
      }
    }
  }

  Future<void> _onSubscribedToNewTestimonies(
    SubscribedToNewTestimonies event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(newTestimony: true);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.subscribeToNewTestimonies();
      } catch (e) {
        emit(currentState);
        emit(TestimonyNotificationError(message: "Unable to subscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.subscribeToNewTestimonies();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(TestimonyNotificationError(message: "Unable to subscribe"));
      }
    }
  }

  Future<void> _onUnsubscribedFromNewTestimonies(
    UnsubscribedFromNewTestimonies event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(newTestimony: false);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.unsubscribeFromNewTestimonies();
      } catch (e) {
        emit(currentState);
        emit(TestimonyNotificationError(message: "Unable to unsubscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.unsubscribeFromNewTestimonies();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(TestimonyNotificationError(message: "Unable to unsubscribe"));
      }
    }
  }

  Future<void> _onSubscribedToNewForumThreads(
    SubscribedToNewForumThreads event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(newForumThread: true);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.subscribeToNewForumThreads();
      } catch (e) {
        emit(currentState);
        emit(NotificationSettingsError(message: "Unable to subscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.subscribeToNewForumThreads();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(NotificationSettingsError(message: "Unable to subscribe"));
      }
    }
  }

  Future<void> _onUnsubscribedFromNewForumThreads(
    UnsubscribedFromNewForumThreads event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(newForumThread: false);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.unsubscribeFromNewForumThreads();
      } catch (e) {
        emit(currentState);
        emit(NotificationSettingsError(message: "Unable to unsubscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.unsubscribeFromNewForumThreads();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(NotificationSettingsError(message: "Unable to unsubscribe"));
      }
    }
  }

  Future<void> _onSubscribedToForumCommentReplies(
    SubscribedToForumCommentReplies event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(forumCommentReplies: true);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.subscribeToForumCommentReplies();
      } catch (e) {
        emit(currentState);
        emit(NotificationSettingsError(message: "Unable to subscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.subscribeToForumCommentReplies();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(NotificationSettingsError(message: "Unable to subscribe"));
      }
    }
  }

  Future<void> _onUnsubscribedFromForumCommentReplies(
    UnsubscribedFromForumCommentReplies event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings = currentState.notificationSettings
          .copyWith(forumCommentReplies: false);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService
            .unsubscribeFromForumCommentReplies();
      } catch (e) {
        emit(currentState);
        emit(NotificationSettingsError(message: "Unable to unsubscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService
            .unsubscribeFromForumCommentReplies();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(NotificationSettingsError(message: "Unable to unsubscribe"));
      }
    }
  }

  Future<void> _onSubscribedToForumCommentLikes(
    SubscribedToForumCommentLikes event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(forumCommentLikes: true);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.subscribeToForumCommentLikes();
      } catch (e) {
        emit(currentState);
        emit(NotificationSettingsError(message: "Unable to subscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.subscribeToForumCommentLikes();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(NotificationSettingsError(message: "Unable to subscribe"));
      }
    }
  }

  Future<void> _onUnsubscribedFromForumCommentLikes(
    UnsubscribedFromForumCommentLikes event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(forumCommentLikes: false);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.unsubscribeFromForumCommentLikes();
      } catch (e) {
        emit(currentState);
        emit(NotificationSettingsError(message: "Unable to unsubscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.unsubscribeFromForumCommentLikes();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(NotificationSettingsError(message: "Unable to unsubscribe"));
      }
    }
  }

  Future<void> _onSubscribedToForumThreadComments(
    SubscribedToForumThreadComments event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings =
          currentState.notificationSettings.copyWith(forumThreadComments: true);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService.subscribeToForumThreadComments();
      } catch (e) {
        emit(currentState);
        emit(NotificationSettingsError(message: "Unable to subscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService.subscribeToForumThreadComments();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(NotificationSettingsError(message: "Unable to subscribe"));
      }
    }
  }

  Future<void> _onUnsubscribedFromForumThreadComments(
    UnsubscribedFromForumThreadComments event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationSettingsPositions) {
      final updatedSettings = currentState.notificationSettings
          .copyWith(forumThreadComments: false);
      emit(
          NotificationSettingsPositions(notificationSettings: updatedSettings));
      try {
        await _iNotificationSettingsService
            .unsubscribeFromForumThreadComments();
      } catch (e) {
        emit(currentState);
        emit(NotificationSettingsError(message: "Unable to unsubscribe"));
      }
    } else {
      try {
        await _iNotificationSettingsService
            .unsubscribeFromForumThreadComments();
        add(NotificationSettingsRequested());
      } catch (e) {
        emit(NotificationSettingsError(message: "Unable to unsubscribe"));
      }
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
