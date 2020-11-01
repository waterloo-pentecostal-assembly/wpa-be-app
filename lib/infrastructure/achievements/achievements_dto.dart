import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/domain/achievements/entities.dart';

import '../common/helpers.dart';

class AchievementsDto {
  final int currentStreak;
  final int longestStreak;
  final int perfectSeries;

  factory AchievementsDto.fromJson(Map<String, dynamic> json) {
    return AchievementsDto._(
      currentStreak: findOrThrowException(json, 'current_streak'),
      longestStreak: findOrThrowException(json, 'longest_streak'),
      perfectSeries: findOrThrowException(json, 'perfect_series'),
    );
  }

  factory AchievementsDto.fromFirestore(DocumentSnapshot doc) {
    return AchievementsDto.fromJson(doc.data());
  }

  const AchievementsDto._({
    @required this.currentStreak,
    @required this.longestStreak,
    @required this.perfectSeries,
  });
}

extension AchievementsDtoX on AchievementsDto {
  Achievements toDomain() {
    return Achievements(
      currentStreak: this.currentStreak,
      longestStreak: this.longestStreak,
      perfectSeries: this.perfectSeries,
    );
  }
}
