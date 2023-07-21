import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/domain/achievements/entities.dart';

import '../common/helpers.dart';

class AchievementsDto {
  final int seriesProgress;

  factory AchievementsDto.fromJson(Map<String, dynamic> json) {
    return AchievementsDto._(
      seriesProgress: findOrDefaultTo(json, 'series_progress', 0),
    );
  }

  factory AchievementsDto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = (doc.data() ?? {}) as Map<String, dynamic>;
    return AchievementsDto.fromJson(data);
  }

  const AchievementsDto._({
    required this.seriesProgress,
  });
}

extension AchievementsDtoX on AchievementsDto {
  Achievements toDomain() {
    return Achievements(
      seriesProgress: this.seriesProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'series_progress': this.seriesProgress,
    };
  }
}
