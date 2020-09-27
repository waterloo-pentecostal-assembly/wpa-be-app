import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/common/value_objects.dart';
import '../common/helpers.dart';
import 'helpers.dart';

class BibleSeriesDto {
  final String id;
  final String title;
  final String subTitle;
  final String imageUrl;
  final Timestamp startDate;
  final Timestamp endDate;
  final bool isActive;
  final List<SeriesContentSnippetDto> seriesContentSnippet;

  factory BibleSeriesDto.fromJson(Map<String, dynamic> json) {
    List<dynamic> _seriesContentSnippetFirebase = json['series_content_snippet'] ?? [];
    List<SeriesContentSnippetDto> _seriesContentSnippet = [];

    _seriesContentSnippetFirebase.forEach((element) {
      _seriesContentSnippet.add(SeriesContentSnippetDto.fromFirestore(element));
    });

    return BibleSeriesDto._(
      title: findOrThrowException(json, 'title'),
      subTitle: findOrThrowException(json, 'sub_title'),
      imageUrl: findOrThrowException(json, 'image_url'),
      startDate: findOrThrowException(json, 'start_date'),
      endDate: findOrThrowException(json, 'end_date'),
      isActive: json['is_active'] ?? false,
      seriesContentSnippet: _seriesContentSnippet,
    );
  }

  factory BibleSeriesDto.fromFirestore(DocumentSnapshot doc) {
    return BibleSeriesDto.fromJson(doc.data()).copyWith(id: doc.id);
  }

  BibleSeriesDto copyWith({
    String id,
    String title,
    String subTitle,
    String imageUrl,
    Timestamp startDate,
    Timestamp endDate,
    bool isActive,
    List<SeriesContentSnippetDto> seriesContentSnippet,
  }) {
    return BibleSeriesDto._(
      id: id ?? this.id,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      seriesContentSnippet: seriesContentSnippet ?? this.seriesContentSnippet,
    );
  }

  const BibleSeriesDto._({
    this.id,
    @required this.title,
    @required this.subTitle,
    @required this.imageUrl,
    @required this.startDate,
    @required this.endDate,
    @required this.isActive,
    @required this.seriesContentSnippet,
  });
}

extension BibleSeriesDtoX on BibleSeriesDto {
  BibleSeries toDomain() {
    List<SeriesContentSnippet> _seriesContentSnippet = [];
    this.seriesContentSnippet.forEach((element) {
      _seriesContentSnippet.add(element.toDomain());
    });

    return BibleSeries(
      id: UniqueId.fromUniqueString(this.id),
      title: this.title,
      subTitle: this.subTitle,
      imageUrl: this.imageUrl,
      startDate: this.startDate,
      endDate: this.endDate,
      isActive: this.isActive,
      seriesContentSnippet: _seriesContentSnippet,
    );
  }
}

class SeriesContentSnippetDto {
  final Map<String, dynamic> contentTypes;
  final Timestamp date;

  factory SeriesContentSnippetDto.fromJson(Map<String, dynamic> json) {
    return SeriesContentSnippetDto._(
      contentTypes: json['content_types'],
      date: json['date'],
    );
  }

  factory SeriesContentSnippetDto.fromFirestore(dynamic seriesSnippet) {
    return SeriesContentSnippetDto.fromJson(seriesSnippet);
  }

  const SeriesContentSnippetDto._({
    @required this.contentTypes,
    @required this.date,
  });

  @override
  String toString() {
    return 'contentTypes: $contentTypes, date: $date';
  }
}

extension SeriesContentSnippetDtoX on SeriesContentSnippetDto {
  SeriesContentSnippet toDomain() {
    Map<SeriesContentType, UniqueId> contentTypes = {};
    this.contentTypes.forEach((key, value) {
      final SeriesContentType newKey = contentTypeMapper(key);
      if (newKey != null) {
        contentTypes[newKey] = UniqueId.fromUniqueString(value);
      }
    });

    return SeriesContentSnippet(
      contentTypes: contentTypes,
      date: this.date,
    );
  }
}
