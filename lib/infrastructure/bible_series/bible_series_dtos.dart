import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../../domain/common/value_objects.dart';

class BibleSeriesDto {
  final String id;
  final String title;
  final String subTitle;
  final String imageUrl;
  final Timestamp startDate;
  final Timestamp endDate;

  factory BibleSeriesDto.fromJson(Map<String, dynamic> json) {
    List<String> expectedKeys = [
      'title',
      'sub_title',
      'image_url',
      'start_date',
      'end_date'
    ];

    for (final key in expectedKeys) {
      if (json[key] == null) {
        throw MissingKeyException('$key expected in bible_series document');
      }
    }

    return BibleSeriesDto._(
      title: json['title'],
      subTitle: json['sub_title'],
      imageUrl: json['image_url'],
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }

  factory BibleSeriesDto.fromFirestore(DocumentSnapshot document) {
    return BibleSeriesDto.fromJson(document.data())
        .copyWith(id: document.id);
  }

  BibleSeriesDto copyWith({
    String id,
    String title,
    String subTitle,
    String imageUrl,
    Timestamp startDate,
    Timestamp endDate,
  }) {
    return BibleSeriesDto._(
      id: id ?? this.id,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  const BibleSeriesDto._({
    this.id,
    @required this.title,
    @required this.subTitle,
    @required this.imageUrl,
    @required this.startDate,
    @required this.endDate,
  });
}

extension BibleSeriesDtoX on BibleSeriesDto {
  BibleSeries toDomain() {
    return BibleSeries(
      id: UniqueId.fromUniqueString(this.id),
      title: this.title,
      subTitle: this.subTitle,
      imageUrl: this.imageUrl,
      startDate: this.startDate,
      endDate: this.endDate,
    );
  }
}
