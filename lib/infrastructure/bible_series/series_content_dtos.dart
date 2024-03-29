import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/services/firebase_storage_service.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../common/helpers.dart';

class SeriesContentDto {
  final String id;
  final String title;
  final String subTitle;
  final String contentType;
  final Timestamp date;
  final List<SeriesContentBodyDto> body;

  factory SeriesContentDto.fromJson(Map<String, dynamic> json) {
    List<dynamic> _bodyFirebase = findOrThrowException(json, 'body');
    List<SeriesContentBodyDto> _body = [];

    _bodyFirebase.forEach((element) {
      _body.add(SeriesContentBodyDto.fromFirestore(element));
    });

    return SeriesContentDto._(
      title: findOrThrowException(json, 'title'),
      subTitle: json['sub_title'] ?? '',
      contentType: findOrThrowException(json, 'content_type'),
      date: findOrThrowException(json, 'date'),
      body: _body,
    );
  }

  factory SeriesContentDto.fromFirestore(DocumentSnapshot doc) {
    return SeriesContentDto.fromJson(doc.data()).copyWith(id: doc.id);
  }

  SeriesContentDto copyWith({
    String id,
    final String title,
    final String subTitle,
    final String contentType,
    final Timestamp date,
    final List<SeriesContentBodyDto> body,
  }) {
    return SeriesContentDto._(
      id: id ?? this.id,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      contentType: contentType ?? this.contentType,
      date: date ?? this.date,
      body: body ?? this.body,
    );
  }

  const SeriesContentDto._({
    this.id,
    @required this.title,
    @required this.subTitle,
    @required this.contentType,
    @required this.date,
    @required this.body,
  });
}

extension SeriesContentDtoX on SeriesContentDto {
  Future<SeriesContent> toDomain(
      FirebaseStorageService firebaseStorageService) async {
    List<ISeriesContentBody> _body = [];

    for (SeriesContentBodyDto element in this.body) {
      ISeriesContentBody seriesContentBody =
          await element.toDomain(body.indexOf(element), firebaseStorageService);
      _body.add(seriesContentBody);
    }
    return SeriesContent(
      id: this.id,
      title: this.title,
      subTitle: this.subTitle,
      contentType: this.contentType.toUpperCase(),
      date: this.date,
      body: _body,
    );
  }
}

class SeriesContentBodyDto {
  final String bodyType;
  final Map<String, dynamic> properties;

  factory SeriesContentBodyDto.fromJson(Map<String, dynamic> json) {
    String _bodyType = json['body_type'];
    Map<String, dynamic> _properties = {};

    if (_bodyType == 'audio') {
      _properties['audioFileUrl'] =
          findOrThrowException(json, 'audio_file_url');
      _properties['title'] = findOrDefaultTo(json, 'title', '');
    } else if (_bodyType == 'text') {
      _properties['paragraphs'] = findOrThrowException(json, 'paragraphs');
    } else if (_bodyType == 'question') {
      _properties['questions'] = findOrThrowException(json, 'questions');
    } else if (_bodyType == 'scripture') {
      _properties['bibleVersion'] = findOrThrowException(json, 'bible_version');
      _properties['attribution'] = findOrThrowException(json, 'attribution');
      _properties['scriptures'] = findOrThrowException(json, 'scriptures');
    } else if (_bodyType == 'image_input') {
    } else if (_bodyType == 'link') {
      _properties['title'] = findOrDefaultTo(json, 'title', '');
      _properties['text'] = findOrThrowException(json, 'text');
      _properties['link'] = findOrThrowException(json, 'link');
    } else if (_bodyType == 'title') {
      _properties['text'] = findOrThrowException(json, 'text');
    } else if (_bodyType == 'divider') {
    } else {
      throw BibleSeriesException(
        message: 'Invalid body_type: $_bodyType',
        code: BibleSeriesExceptionCode.INVALID_CONTENT_BODY,
      );
    }

    return SeriesContentBodyDto._(
      bodyType: _bodyType,
      properties: _properties,
    );
  }

  factory SeriesContentBodyDto.fromFirestore(dynamic contentBody) {
    return SeriesContentBodyDto.fromJson(contentBody);
  }

  SeriesContentBodyDto._({
    this.bodyType,
    this.properties,
  });
}

extension SeriesContentBodyDtoX on SeriesContentBodyDto {
  // ignore: missing_return
  Future<ISeriesContentBody> toDomain(
      int index, FirebaseStorageService firebaseStorageService) async {
    if (this.bodyType == 'audio') {
      AudioBodyProperties bodyProperties = AudioBodyProperties();
      bodyProperties.audioFileUrl = this.properties['audioFileUrl'];
      bodyProperties.title = this.properties['title'];

      return AudioBody(
        type: SeriesContentBodyType.AUDIO,
        properties: bodyProperties,
      );
    } else if (this.bodyType == 'text') {
      TextBodyProperties bodyProperties = TextBodyProperties();
      List<String> _paragraphs = [];

      this.properties['paragraphs'].forEach((element) {
        _paragraphs.add(element);
      });
      bodyProperties.paragraphs = _paragraphs;

      return TextBody(
        type: SeriesContentBodyType.TEXT,
        properties: bodyProperties,
      );
    } else if (this.bodyType == 'scripture') {
      ScriptureBodyProperties bodyProperties = ScriptureBodyProperties();
      bodyProperties.bibleVersion = this.properties['bibleVersion'];
      bodyProperties.attribution = this.properties['attribution'];
      bodyProperties.scriptures = [];

      List<dynamic> _scriptures = this.properties['scriptures'];
      _scriptures.forEach((element) {
        Map<String, String> _verses = {};
        Map<String, dynamic> _versesFirebase =
            findOrThrowException(element, 'verses');

        _versesFirebase.forEach((key, value) {
          _verses[key] = value;
        });

        bodyProperties.scriptures.add(
          Scripture(
            title: element['title'] ?? '',
            book: findOrThrowException(element, 'book'),
            chapter: findOrThrowException(element, 'chapter'),
            fullChapter: findOrDefaultTo(element, 'full_chapter', false),
            verses: _verses,
          ),
        );
      });

      return ScriptureBody(
        type: SeriesContentBodyType.SCRIPTURE,
        properties: bodyProperties,
      );
    } else if (this.bodyType == 'question') {
      QuestionBodyProperties bodyProperties = QuestionBodyProperties();
      List<Question> _questions = [];
      dynamic questions = this.properties['questions'];

      questions.forEach((question) {
        _questions.add(
          Question(
            location: [index, questions.indexOf(question)],
            question: question,
          ),
        );
      });

      bodyProperties.questions = _questions;

      return QuestionBody(
        type: SeriesContentBodyType.QUESTION,
        properties: bodyProperties,
      );
    } else if (this.bodyType == 'image_input') {
      return ImageInputBody(type: SeriesContentBodyType.IMAGE_INPUT);
    } else if (this.bodyType == 'link') {
      LinkBodyProperties properties = LinkBodyProperties();
      properties.title = this.properties['title'];
      properties.text = this.properties['text'];
      properties.link = this.properties['link'];
      return LinkBody(
        type: SeriesContentBodyType.LINK,
        properties: properties,
      );
    } else if (this.bodyType == 'title') {
      TitleBodyProperties properties = TitleBodyProperties();
      properties.text = this.properties['text'];
      return TitleBody(
        type: SeriesContentBodyType.TITLE,
        properties: properties,
      );
    } else if (this.bodyType == 'divider') {
      return DividerBody();
    }
  }
}
