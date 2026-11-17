import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../common/helpers.dart';

/// `bible_series/{id}/series_content/{contentId}` document.
class SeriesContentDto {
  const SeriesContentDto({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.contentType,
    required this.date,
    required this.body,
  });

  factory SeriesContentDto.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() ?? {}) as Map<String, dynamic>;
    final List<dynamic> body = findOrThrowException(data, 'body');
    return SeriesContentDto(
      id: doc.id,
      title: findOrThrowException(data, 'title'),
      subTitle: data['sub_title'] ?? '',
      contentType: findOrThrowException(data, 'content_type'),
      date: findOrThrowException(data, 'date'),
      body: body
          .map((e) => SeriesContentBodyDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String title;
  final String subTitle;
  final String contentType;
  final Timestamp date;
  final List<SeriesContentBodyDto> body;

  SeriesContent toDomain() {
    return SeriesContent(
      id: id,
      title: title,
      subTitle: subTitle,
      contentType: contentType.toUpperCase(),
      date: date.toDate(),
      body: [for (var i = 0; i < body.length; i++) body[i].toDomain(i)],
    );
  }
}

class SeriesContentBodyDto {
  SeriesContentBodyDto._({required this.bodyType, required this.properties});

  factory SeriesContentBodyDto.fromJson(Map<String, dynamic> json) {
    final String bodyType = json['body_type'];
    final properties = <String, dynamic>{};
    switch (bodyType) {
      case 'audio':
        properties['audioFileUrl'] =
            findOrThrowException(json, 'audio_file_url');
        properties['title'] = findOrDefaultTo(json, 'title', '');
      case 'text':
        properties['paragraphs'] = findOrThrowException(json, 'paragraphs');
      case 'question':
        properties['questions'] = findOrThrowException(json, 'questions');
      case 'scripture':
        properties['bibleVersion'] =
            findOrThrowException(json, 'bible_version');
        properties['attribution'] = findOrThrowException(json, 'attribution');
        properties['scriptures'] = findOrThrowException(json, 'scriptures');
      case 'image_input':
      case 'divider':
        break;
      case 'link':
        properties['title'] = findOrDefaultTo(json, 'title', '');
        properties['text'] = findOrThrowException(json, 'text');
        properties['link'] = findOrThrowException(json, 'link');
      case 'video':
        properties['link'] = findOrThrowException(json, 'link');
        properties['title'] = findOrDefaultTo(json, 'title', '');
      case 'title':
        properties['text'] = findOrThrowException(json, 'text');
      default:
        throw BibleSeriesException(
          message: 'Invalid body_type: $bodyType',
          code: BibleSeriesExceptionCode.invalidContentBody,
        );
    }
    return SeriesContentBodyDto._(bodyType: bodyType, properties: properties);
  }

  final String bodyType;
  final Map<String, dynamic> properties;

  SeriesContentBody toDomain(int index) {
    switch (bodyType) {
      case 'audio':
        return AudioBody(
          audioFileUrl: properties['audioFileUrl'],
          title: properties['title'],
        );
      case 'text':
        return TextBody(
          paragraphs: (properties['paragraphs'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
        );
      case 'scripture':
        final scriptures =
            (properties['scriptures'] as List<dynamic>).map((element) {
          final Map<String, dynamic> verses =
              findOrThrowException(element, 'verses');
          return Scripture(
            title: element['title'] ?? '',
            book: findOrThrowException(element, 'book'),
            chapter: findOrThrowException(element, 'chapter'),
            fullChapter: findOrDefaultTo(element, 'full_chapter', false),
            verses: verses.map((k, v) => MapEntry(k, v as String)),
          );
        }).toList();
        return ScriptureBody(
          bibleVersion: properties['bibleVersion'],
          attribution: properties['attribution'],
          scriptures: scriptures,
        );
      case 'question':
        final questions = properties['questions'] as List<dynamic>;
        return QuestionBody(
          questions: [
            for (var j = 0; j < questions.length; j++)
              Question(location: [index, j], question: questions[j]),
          ],
        );
      case 'image_input':
        return const ImageInputBody();
      case 'link':
        return LinkBody(
          title: properties['title'],
          text: properties['text'],
          link: properties['link'],
        );
      case 'video':
        return VideoBody(title: properties['title'], link: properties['link']);
      case 'title':
        return TitleBody(text: properties['text']);
      case 'divider':
        return const DividerBody();
    }
    return const EmptyBody();
  }
}
