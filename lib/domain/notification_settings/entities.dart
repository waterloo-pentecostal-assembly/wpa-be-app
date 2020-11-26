import 'package:flutter/material.dart';

class NotificationSettingsEntity {
  final String id;
  final bool dailyEngagementReminder;

  NotificationSettingsEntity({
    @required this.id,
    this.dailyEngagementReminder = false,
  });
}
