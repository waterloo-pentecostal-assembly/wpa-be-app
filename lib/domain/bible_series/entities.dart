import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/domain/common/value_objects.dart';

// TODO: create field to content info
class BibleSeries {
  final UniqueId id;
  final String title;
  final String subTitle;
  final String imageUrl;
  final Timestamp startDate;
  final Timestamp endDate;

  BibleSeries({
    @required this.id,
    @required this.title,
    @required this.subTitle,
    @required this.imageUrl,
    @required @required this.startDate,
    @required this.endDate,
  });

  @override
  String toString() {
    return 'id: ${id.value}, title: $title, subtitle: $subTitle, imageUrl: $imageUrl, startDate: $startDate, endDate: $endDate';
  }
}

// class BibleSeriesDetail {
//   final UniqueId id;
//   final String title;
//   final String subTitle;
//   final String imageUrl;
//   final Timestamp startDate;
//   final Timestamp endDate;
//   final Map<String, Timestamp> contentIds;

//   BibleSeriesDetail(
//     this.id,
//     this.title,
//     this.subTitle,
//     this.imageUrl,
//     this.startDate,
//     this.endDate,
//     this.contentIds,
//   );
// }

// class SeriesContent {
//   final String id;
//   final Map body;
//   final Timestamp date;
//   final String footer;
//   final String title;
//   final String subTitle;
//   final SeriesContentType type;
// }

// entity for scriptures
// TODO: restructure how data is represented in firestore
class ScriptureEngagement {}

// entity for audio
class AudioEngagement {}

// entity for text
class TextEngagement {}

enum SeriesContentType {
  read,
  listen,
  pray,
  reflect,
}

enum SeriesContentBodyType {
  scripture,
  audio,
  text,
}
