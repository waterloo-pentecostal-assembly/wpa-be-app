import 'package:flutter/material.dart';

class NotificationSettingsEntity {
  final String id;
  final bool dailyEngagementReminder;
  final bool prayers;

  NotificationSettingsEntity({
    required this.id,
    required this.dailyEngagementReminder,
    required this.prayers,
  });
}
