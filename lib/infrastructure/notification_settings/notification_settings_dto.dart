import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/notification_settings/entities.dart';
import '../common/helpers.dart';

class NotificationSettingsDto {
  final String id;
  final bool dailyEngagementReminder;
  final bool prayers;

  factory NotificationSettingsDto.fromFirestore(DocumentSnapshot doc) {
    var data = (doc.data() ?? {}) as Map<String, dynamic>;
    return NotificationSettingsDto._(
      id: doc.id,
      dailyEngagementReminder:
          findOrDefaultTo(data, 'daily_engagement_reminder', false),
      prayers: findOrDefaultTo(data, 'prayers', false),
    );
  }

  NotificationSettingsDto._({
    required this.id,
    required this.dailyEngagementReminder,
    required this.prayers,
  });
}

extension NotificationSettingsDtoX on NotificationSettingsDto {
  NotificationSettingsEntity toDomain() {
    return NotificationSettingsEntity(
      id: this.id,
      dailyEngagementReminder: this.dailyEngagementReminder,
      prayers: this.prayers,
    );
  }
}
