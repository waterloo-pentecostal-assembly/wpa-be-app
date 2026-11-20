import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/bible_series/exceptions.dart';
import 'package:wpa_app/infrastructure/bible_series/bible_series_repository.dart';

import '_support/fakes.dart';

Map<String, dynamic> seriesDoc({
  required int startDay,
  bool isActive = true,
  bool isVisible = true,
}) =>
    {
      'title': 'Series $startDay',
      'sub_title': 'Sub',
      'image_gs_location': 'gs://bucket/s$startDay.jpg',
      'start_date': ts(startDay),
      'end_date': ts(startDay + 1),
      'is_active': isActive,
      'is_visible': isVisible,
      'series_content_snippet': [
        {
          'date': ts(startDay),
          'content_types': [
            {'content_type': 'read', 'content_id': 'c$startDay'},
          ],
        },
      ],
    };

void main() {
  late FakeFirebaseFirestore firestore;
  late BibleSeriesRepository repository;

  CollectionReference<Map<String, dynamic>> series() =>
      firestore.collection('bible_series');

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository =
        BibleSeriesRepository(firestore, createStorageMock(), sessionWith());
  });

  test('getBibleSeries maps documents newest first and skips malformed ones',
      () async {
    await series().doc('s1').set(seriesDoc(startDay: 1));
    await series().doc('s5').set(seriesDoc(startDay: 5));
    await series().doc('bad').set({...seriesDoc(startDay: 3), 'title': null});
    await series().doc('hidden').set(seriesDoc(startDay: 4, isVisible: false));

    final result = await repository.getBibleSeries(limit: 10);

    expect(result.map((s) => s.id), ['s5', 's1']);
    final s5 = result.first;
    expect(s5.imageUrl, downloadUrlFor('gs://bucket/s5.jpg'));
    expect(s5.startDate, day(5));
    final content = s5.seriesContentSnippet.single.availableContentTypes.single;
    expect(content.seriesContentType, 'READ');
    expect(content.contentId, 'c5');
  });

  test('hasActiveBibleSeries reads the newest visible series flag', () async {
    expect(await repository.hasActiveBibleSeries(), isFalse);
    await series().doc('old').set(seriesDoc(startDay: 1));
    await series().doc('new').set(seriesDoc(startDay: 5, isActive: false));
    expect(await repository.hasActiveBibleSeries(), isFalse);
    await series().doc('newest').set(seriesDoc(startDay: 9));
    expect(await repository.hasActiveBibleSeries(), isTrue);
  });

  test('getBibleSeriesDetails throws when the series does not exist', () {
    expect(
      repository.getBibleSeriesDetails(bibleSeriesId: 'nope'),
      throwsA(isA<BibleSeriesException>().having(
          (e) => e.code, 'code', BibleSeriesExceptionCode.noSeriesContent)),
    );
  });

  group('getContentDetails', () {
    Future<void> setContent(List<Map<String, dynamic>> body) =>
        series().doc('s1').collection('series_content').doc('c1').set({
          'title': 'Day 1',
          'content_type': 'read',
          'date': ts(1),
          'body': body,
        });

    test('parses every body type', () async {
      await setContent([
        {'body_type': 'title', 'text': 'Hello'},
        {
          'body_type': 'text',
          'paragraphs': ['p1', 'p2']
        },
        {
          'body_type': 'scripture',
          'passage_ids': ['JHN.3.16-JHN.3.18', 'PSA.23'],
        },
        {
          'body_type': 'question',
          'questions': ['Q1', 'Q2'],
        },
        {'body_type': 'audio', 'audio_file_url': 'https://a.mp3'},
        {'body_type': 'video', 'link': 'https://v'},
        {'body_type': 'link', 'text': 'More', 'link': 'https://l'},
        {'body_type': 'image_input'},
        {'body_type': 'divider'},
      ]);

      final content = await repository.getContentDetails(
          bibleSeriesId: 's1', seriesContentId: 'c1');

      expect(content.contentType, 'READ');
      expect(content.subTitle, '');
      expect(content.body.map((b) => b.runtimeType), [
        TitleBody,
        TextBody,
        ScriptureBody,
        QuestionBody,
        AudioBody,
        VideoBody,
        LinkBody,
        ImageInputBody,
        DividerBody,
      ]);
      expect(
        content.body[2],
        const ScriptureBody(passageIds: ['JHN.3.16-JHN.3.18', 'PSA.23']),
      );
      final questions = (content.body[3] as QuestionBody).questions;
      expect(questions.map((q) => q.location), [
        [3, 0],
        [3, 1],
      ]);
      expect((content.body[4] as AudioBody).title, '');
    });

    test('an unknown body type throws invalidContentBody', () async {
      await setContent([
        {'body_type': 'hologram'},
      ]);
      expect(
        repository.getContentDetails(
            bibleSeriesId: 's1', seriesContentId: 'c1'),
        throwsA(isA<BibleSeriesException>().having((e) => e.code, 'code',
            BibleSeriesExceptionCode.invalidContentBody)),
      );
    });
  });
}
