import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../../domain/common/value_objects.dart';
import '../common/helpers.dart';
import 'helpers.dart';

class SeriesContentDto {
  final String id;
  final String title;
  final String subTitle;
  final String contentType;
  final Timestamp date;
  final List<SeriesContentBodyDto> body;

  factory SeriesContentDto.fromJson(Map<String, dynamic> json) {
    List<dynamic> _bodyFirebase = findOrThrowMissingKeyException(json, 'body');
    List<SeriesContentBodyDto> _body = [];

    _bodyFirebase.forEach((element) {
      _body.add(SeriesContentBodyDto.fromFirestore(element));
    });

    return SeriesContentDto._(
      title: findOrThrowMissingKeyException(json, 'title'),
      subTitle: json['sub_title'] ?? '',
      contentType: findOrThrowMissingKeyException(json, 'content_type'),
      date: findOrThrowMissingKeyException(json, 'date'),
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
  SeriesContent toDomain() {
    List<ISeriesContentBody> _body = [];
    this.body.forEach((element) {
      _body.add(element.toDomain());
    });

    return SeriesContent(
      id: UniqueId.fromUniqueString(this.id),
      title: this.title,
      subTitle: this.subTitle,
      contentType: contentTypeMapper(this.contentType),
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
      _properties['audio_file_url'] = findOrThrowMissingKeyException(json, 'audio_file_url');
    } else if (_bodyType == 'text') {
      _properties['paragraphs'] = findOrThrowMissingKeyException(json, 'paragraphs');
    } else if (_bodyType == 'question') {
      _properties['questions'] = findOrThrowMissingKeyException(json, 'questions');
    } else if (_bodyType == 'scripture') {
      _properties['bibleVersion'] = findOrThrowMissingKeyException(json, 'bible_version');
      _properties['attribution'] = findOrThrowMissingKeyException(json, 'attribution');
      _properties['scriptures'] = findOrThrowMissingKeyException(json, 'scriptures');
    } else {
      throw InvalidContentBodyType(message: 'Invalid body_type: $_bodyType');
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
  ISeriesContentBody toDomain() {
    if (this.bodyType == 'audio') {
      AudioBodyProperties bodyProperties = AudioBodyProperties();
      bodyProperties.audioFileUrl = this.properties['audio_file_url'];

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
      bodyProperties.bibleVersion = this.properties['bible_version'];
      bodyProperties.attribution = this.properties['attribution'];
      bodyProperties.scriptures = [];

      List<dynamic> _scriptures = this.properties['scriptures'];
      _scriptures.forEach((element) {
        Map<String, String> _verses = {};
        Map<String, dynamic> _versesFirebase = findOrThrowMissingKeyException(element, 'verses');

        _versesFirebase.forEach((key, value) {
          _verses[key] = value;
        });

        bodyProperties.scriptures.add(
          Scripture(
            title: element['title'] ?? null,
            book: findOrThrowMissingKeyException(element, 'book'),
            chapter: findOrThrowMissingKeyException(element, 'chapter'),
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
      List<String> _questions = [];

      this.properties['questions'].forEach((element) {
        _questions.add(element);
      });
      bodyProperties.questions = _questions;

      return QuestionBody(
        type: SeriesContentBodyType.QUESTION,
        properties: bodyProperties,
      );
    }
  }
}
