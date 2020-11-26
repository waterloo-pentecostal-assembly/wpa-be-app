import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'notification_settings_event.dart';
part 'notification_settings_state.dart';

class NotificationSettingsBloc extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  NotificationSettingsBloc() : super(NotificationSettingsInitial());

  @override
  Stream<NotificationSettingsState> mapEventToState(
    NotificationSettingsEvent event,
  ) async* {
    // TODO: implement mapEventToState
  }
}
