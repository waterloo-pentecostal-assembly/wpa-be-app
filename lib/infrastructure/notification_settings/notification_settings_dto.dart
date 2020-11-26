import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/notification_settings/entities.dart';
import '../common/helpers.dart';

class NotificationSettingsDto {
  final String id;
  final bool dailyEngagementReminder;

  factory NotificationSettingsDto.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsDto._(
      dailyEngagementReminder: findOrDefaultTo(json, 'daily_engagement_reminder', false),
    );
  }

  factory NotificationSettingsDto.fromFirestore(DocumentSnapshot doc) {
    return NotificationSettingsDto.fromJson(doc.data()).copyWith(id: doc.id);
  }

  NotificationSettingsDto copyWith({
    String id,
    String description,
  }) {
    return NotificationSettingsDto._(
      id: id ?? this.id,
      dailyEngagementReminder: dailyEngagementReminder ?? this.dailyEngagementReminder,
    );
  }

  NotificationSettingsDto._({
    this.id,
    @required this.dailyEngagementReminder,
  });
}

extension NotificationSettingsDtoX on NotificationSettingsDto {
  NotificationSettingsEntity toDomain() {
    return NotificationSettingsEntity(
      id: this.id,
      dailyEngagementReminder: this.dailyEngagementReminder,
    );
  }
}
