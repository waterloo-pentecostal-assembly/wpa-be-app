import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/notifications/entities.dart';

class NotificationsState extends Equatable {
  const NotificationsState({this.latest, this.id = 0});

  /// Most recent foreground notification to show as an in-app banner.
  final PushNotification? latest;
  final int id;

  @override
  List<Object?> get props => [latest, id];
}

/// Foreground push notifications -> in-app banner state.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(Stream<PushNotification> foregroundMessages)
      : super(const NotificationsState()) {
    _sub = foregroundMessages.listen((n) {
      if (!isClosed) emit(NotificationsState(latest: n, id: state.id + 1));
    });
  }

  late final StreamSubscription<PushNotification> _sub;

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
