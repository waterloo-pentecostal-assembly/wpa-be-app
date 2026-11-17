import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/notification_settings/entities.dart';
import '../../domain/notification_settings/interfaces.dart';
import '../common/load_status.dart';

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.status = LoadStatus.initial,
    this.settings,
    this.errorMessage,
    this.errorId = 0,
  });

  final LoadStatus status;
  final NotificationSettingsEntity? settings;

  /// One-shot error toast.
  final String? errorMessage;
  final int errorId;

  /// Switches are disabled until settings are loaded.
  bool get isEnabled => settings != null;

  bool valueOf(NotificationSetting s) => settings?.valueOf(s) ?? false;

  @override
  List<Object?> get props => [status, settings, errorMessage, errorId];
}

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit(this._service)
      : super(const NotificationSettingsState());

  final INotificationSettingsService _service;

  Future<void> load() async {
    try {
      final settings = await _service.getNotificationSettings();
      if (!isClosed) {
        emit(NotificationSettingsState(
          status: LoadStatus.success,
          settings: settings,
        ));
      }
    } catch (_) {
      if (!isClosed) {
        emit(NotificationSettingsState(
          status: LoadStatus.failure,
          settings: state.settings,
          errorMessage: 'Error loading notification settings',
          errorId: state.errorId + 1,
        ));
      }
    }
  }

  /// Optimistically toggles [setting], reverting on failure.
  Future<void> toggle(NotificationSetting setting, bool enabled) async {
    final previous = state.settings;
    if (previous == null) return;
    emit(NotificationSettingsState(
      status: LoadStatus.success,
      settings: previous.withSetting(setting, enabled),
    ));
    try {
      await _service.setSetting(setting, enabled);
    } catch (_) {
      if (!isClosed) {
        emit(NotificationSettingsState(
          status: LoadStatus.success,
          settings: previous,
          errorMessage:
              enabled ? 'Unable to subscribe' : 'Unable to unsubscribe',
          errorId: state.errorId + 1,
        ));
      }
    }
  }
}
