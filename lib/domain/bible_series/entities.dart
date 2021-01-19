import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  IMAGE_INPUT,
}

class BibleSeries {
  final String id;
  final String title;
  final String subTitle;
  final String imageUrl;
  final String imageGsLocation;
  final Timestamp startDate;
  final Timestamp endDate;
  final bool isActive;
  final List<SeriesContentSnippet> seriesContentSnippet;

  BibleSeries({
    @required this.id,
    @required this.title,
    @required this.subTitle,
    @required this.imageUrl,
    @required this.imageGsLocation,
    @required this.startDate,
    @required this.endDate,
    @required this.isActive,
    @required this.seriesContentSnippet,
  });

  @override
  String toString() {
    return '''id: $id, title: $title, subtitle: $subTitle, imageUrl: $imageUrl, 
              startDate: $startDate, endDate: $endDate, isActive: $isActive, 
              seriesContentSnippet: $seriesContentSnippet''';
  }
}

class SeriesContentSnippet {
  final List<AvailableContentType> availableContentTypes;
  final Timestamp date;
  bool _isCompleted;
  bool _isOnTime;
  bool _isDraft;

  set isCompleted(bool isCompleted) {
    this._isCompleted = isCompleted;
  }

  get isCompleted => _isCompleted;

  set isOnTime(bool isOnTime) {
    this._isOnTime = isOnTime;
  }

  get isOnTime => _isOnTime;

  set isDraft(bool isDraft) {
    this._isDraft = isDraft;
  }

  get isDraft => _isDraft;

  SeriesContentSnippet({
    @required this.availableContentTypes,
    @required this.date,
  });

  @override
  String toString() {
    return 'availableContentTypes: $availableContentTypes, date: $date, isCompleted: $isCompleted, isOnTime: $isOnTime';
  }
}

class AvailableContentType {
  final SeriesContentType seriesContentType;
  final String contentId;
  bool _isCompleted;
  bool _isOnTime;
  bool _isDraft;

  set isCompleted(bool isCompleted) {
    this._isCompleted = isCompleted;
  }

  get isCompleted => _isCompleted;

  set isOnTime(bool isOnTime) {
    this._isOnTime = isOnTime;
  }

  get isOnTime => _isOnTime;

  set isDraft(bool isDraft) {
    this._isDraft = isDraft;
  }

  get isDraft => _isDraft;

  AvailableContentType({
    @required this.seriesContentType,
    @required this.contentId,
  });

  @override
  String toString() {
    return 'seriesContentType: $seriesContentType, contentId: $contentId, isCompleted: $isCompleted, isOnTime: $isOnTime';
  }
}

class SeriesContent {
  final String id;
  final SeriesContentType contentType;
  final Timestamp date;
  final String title;
  final String subTitle;
  final List<ISeriesContentBody> body;

  /// Checks if it possible to have a response for this [SeriesContent]
  bool get isResponsePossible {
    bool check = false;
    this.body.forEach((element) {
      if (element.type == SeriesContentBodyType.QUESTION ||
          element.type == SeriesContentBodyType.IMAGE_INPUT) {
        check = true;
      }
    });
    return check;
  }

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
  List<Question> questions;
}

class Question {
  final String question;
  final List<int> location;

  Question({
    @required this.question,
    @required this.location,
  });
}

class ImageInputBody implements ISeriesContentBody {
  final SeriesContentBodyType type;

  ImageInputBody({
    @required this.type,
  });

  @override
  get properties => {};
}
