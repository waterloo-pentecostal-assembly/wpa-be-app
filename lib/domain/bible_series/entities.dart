import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../common/value_objects.dart';

enum SeriesContentType {
  REFLECT,
  LISTEN,
  SCRIBE,
  DRAW,
  READ,
  PRAY,
  DEVOTIONAL,
  MEMORIZE,
}

enum SeriesContentBodyType {
  AUDIO,
  TEXT,
  SCRIPTURE,
  QUESTION,
}

class BibleSeries {
  final UniqueId id;
  final String title;
  final String subTitle;
  final String imageUrl;
  final Timestamp startDate;
  final Timestamp endDate;
  final bool isActive;
  final List<SeriesContentSnippet> seriesContentSnippet;

  BibleSeries({
    @required this.id,
    @required this.title,
    @required this.subTitle,
    @required this.imageUrl,
    @required this.startDate,
    @required this.endDate,
    @required this.isActive,
    @required this.seriesContentSnippet,
  });

  @override
  String toString() {
    return '''id: ${id.value}, title: $title, subtitle: $subTitle, imageUrl: $imageUrl, 
              startDate: $startDate, endDate: $endDate, isActive: $isActive, 
              seriesContentSnippet: $seriesContentSnippet''';
  }
}

class SeriesContentSnippet {
  final Map<SeriesContentType, UniqueId> contentTypes;
  final Timestamp date;

  SeriesContentSnippet({
    @required this.contentTypes,
    @required this.date,
  });

  @override
  String toString() {
    return 'contentTypes: $contentTypes, date: $date';
  }
}

class SeriesContent {
  final UniqueId id;
  final SeriesContentType contentType;
  final Timestamp date;
  final String title;
  final String subTitle;
  final List<ISeriesContentBody> body;

  SeriesContent({
    @required this.id,
    @required this.contentType,
    @required this.date,
    @required this.title,
    @required this.subTitle,
    @required this.body,
  });

  @override
  String toString() {
    return '''
    id: $id, contentType: $contentType, date: $date, title: $title, subTitle: $subTitle, body: $body
    ''';
  }
}

class ISeriesContentBody {
  final SeriesContentBodyType type;
  final dynamic properties;

  ISeriesContentBody({
    @required this.type,
    @required this.properties,
  });
}

class AudioBody implements ISeriesContentBody {
  final SeriesContentBodyType type;
  final AudioBodyProperties properties;

  AudioBody({
    @required this.type,
    @required this.properties,
  });
}

class AudioBodyProperties {
  String audioFileUrl;
}

class TextBody implements ISeriesContentBody {
  final SeriesContentBodyType type;
  final TextBodyProperties properties;

  TextBody({
    @required this.type,
    @required this.properties,
  });
}

class TextBodyProperties {
  List<String> paragraphs;
}

class ScriptureBody implements ISeriesContentBody {
  final SeriesContentBodyType type;
  final ScriptureBodyProperties properties;

  ScriptureBody({
    @required this.type,
    @required this.properties,
  });
}

class ScriptureBodyProperties {
  String bibleVersion;
  String attribution;
  List<Scripture> scriptures;
}

class Scripture {
  final String book;
  final String chapter;
  final String title;
  final Map<String, String> verses;

  Scripture({
    @required this.book,
    @required this.chapter,
    this.title,
    @required this.verses,
  });
}

class QuestionBody implements ISeriesContentBody {
  final SeriesContentBodyType type;
  final QuestionBodyProperties properties;

  QuestionBody({
    @required this.type,
    @required this.properties,
  });
}

class QuestionBodyProperties {
  List<String> questions;
}
