import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../../services/firebase_storage_service.dart';
import '../common/firestore_data.dart';

/// Parses a `bible_series/{id}` document (resolving its cover image URL).
Future<BibleSeries> parseBibleSeries(
  DocumentSnapshot doc,
  FirebaseStorageService storage,
) async {
  final data = dataOf(doc);
  final imageGsLocation = data.require<String>('image_gs_location');
  return BibleSeries(
    id: doc.id,
    title: data.require<String>('title'),
    subTitle: data.require<String>('sub_title'),
    imageUrl: await storage.getDownloadUrl(imageGsLocation),
    imageGsLocation: imageGsLocation,
    startDate: data.requireDate('start_date'),
    endDate: data.requireDate('end_date'),
    isActive: data.optional('is_active', false),
    isVisible: data.optional('is_visible', false),
    scriptureBibleId: data.require<String>('scripture_bible_id'),
    seriesContentSnippet: [
      for (final day in data.optional<List>('series_content_snippet', const []))
        _parseSnippet(Map<String, dynamic>.from(day as Map)),
    ],
  );
}

/// One day of a series: its date and the contents available that day.
SeriesContentSnippet _parseSnippet(Map<String, dynamic> day) =>
    SeriesContentSnippet(
      date: day.requireDate('date'),
      availableContentTypes: [
        for (final content in day.require<List>('content_types'))
          _parseAvailableContent(Map<String, dynamic>.from(content as Map)),
      ],
    );

AvailableContentType _parseAvailableContent(Map<String, dynamic> content) =>
    AvailableContentType(
      seriesContentType:
          content.require<Object>('content_type').toString().toUpperCase(),
      contentId: content.require<String>('content_id'),
    );

/// Parses a `bible_series/{id}/series_content/{contentId}` document.
SeriesContent parseSeriesContent(DocumentSnapshot doc) {
  final data = dataOf(doc);
  final body = data.require<List>('body');
  return SeriesContent(
    id: doc.id,
    title: data.require<String>('title'),
    subTitle: data.optional('sub_title', ''),
    contentType: data.require<String>('content_type').toUpperCase(),
    date: data.requireDate('date'),
    body: [
      for (var i = 0; i < body.length; i++)
        _parseBody(Map<String, dynamic>.from(body[i] as Map), i),
    ],
  );
}

List<String> _strings(Map<String, dynamic> json, String key) =>
    [for (final e in json.require<List>(key)) e as String];

/// One content body; [index] is its position (used for question locations).
SeriesContentBody _parseBody(Map<String, dynamic> json, int index) {
  final bodyType = json.require<String>('body_type');
  switch (bodyType) {
    case 'audio':
      return AudioBody(
        audioFileUrl: json.require<String>('audio_file_url'),
        title: json.optional('title', ''),
      );
    case 'text':
      return TextBody(paragraphs: _strings(json, 'paragraphs'));
    case 'question':
      final questions = _strings(json, 'questions');
      return QuestionBody(questions: [
        for (var j = 0; j < questions.length; j++)
          Question(location: [index, j], question: questions[j]),
      ]);
    case 'scripture':
      return ScriptureBody(passageIds: _strings(json, 'passage_ids'));
    case 'image_input':
      return const ImageInputBody();
    case 'divider':
      return const DividerBody();
    case 'link':
      return LinkBody(
        title: json.optional('title', ''),
        text: json.require<String>('text'),
        link: json.require<String>('link'),
      );
    case 'video':
      return VideoBody(
        title: json.optional('title', ''),
        link: json.require<String>('link'),
      );
    case 'title':
      return TitleBody(text: json.require<String>('text'));
    default:
      throw BibleSeriesException(
        message: 'Invalid body_type: $bodyType',
        code: BibleSeriesExceptionCode.invalidContentBody,
      );
  }
}
