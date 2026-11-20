import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/common/app_events.dart';
import 'package:wpa_app/application/common/load_status.dart';
import 'package:wpa_app/application/completions/content_detail_cubit.dart';
import 'package:wpa_app/domain/audio/entities.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/common/analytics.dart';
import 'package:wpa_app/domain/common/media_upload.dart';
import 'package:wpa_app/domain/completions/entities.dart';

import '../../helpers/fakes.dart';

const _seriesId = 'series-1';
const _contentId = 'c1';
const _imageLocation = 'gs://bucket/responses/user-1/img.jpg';
const _thumbLocation = 'gs://bucket/responses/user-1/thumbs/img_200x200.jpg';

/// Body 0: text, body 1: two questions, body 2: image input.
final _content = SeriesContent(
  id: _contentId,
  contentType: 'REFLECT',
  date: DateTime(2026, 3, 2),
  title: 'Day 2',
  subTitle: 'Reflect',
  body: const [
    TextBody(paragraphs: ['Read this']),
    QuestionBody(questions: [
      Question(question: 'Q1', location: [1, 0]),
      Question(question: 'Q2', location: [1, 1]),
    ]),
    ImageInputBody(),
  ],
);

final _readOnlyContent = SeriesContent(
  id: 'read-only',
  contentType: 'READ',
  date: DateTime(2026, 3, 2),
  title: 'Day 2',
  subTitle: 'Read',
  body: const [
    TextBody(paragraphs: ['Read this'])
  ],
);

ResponseDetails _text(String s) =>
    ResponseDetails(type: ResponseType.text, response: s);

void main() {
  late FakeBibleSeriesRepository bibleSeries;
  late FakeBiblePassageRepository passages;
  late FakeCompletionsRepository completions;
  late FakeAnalytics analytics;
  late AppEventBus events;
  late FakeSession session;
  late List<CompletionChanged> changes;
  late DateTime now;

  setUp(() {
    bibleSeries = FakeBibleSeriesRepository()
      ..contents[_contentId] = _content
      ..contents['read-only'] = _readOnlyContent;
    passages = FakeBiblePassageRepository();
    completions = FakeCompletionsRepository();
    analytics = FakeAnalytics();
    events = AppEventBus();
    session = FakeSession(buildUser(id: 'user-1'));
    changes = [];
    events.on<CompletionChanged>().listen(changes.add);
    now = DateTime(2026, 3, 2, 10);
  });

  tearDown(() => events.dispose());

  ContentDetailCubit build({String contentId = _contentId}) =>
      ContentDetailCubit(
        bibleSeriesId: _seriesId,
        contentId: contentId,
        bibleSeriesRepository: bibleSeries,
        biblePassageRepository: passages,
        completionsRepository: completions,
        analytics: analytics,
        events: events,
        session: session,
        clock: () => now,
      );

  Future<ContentDetailCubit> loaded({String contentId = _contentId}) async {
    final cubit = build(contentId: contentId);
    await cubit.load();
    analytics.events.clear();
    completions.calls.clear();
    return cubit;
  }

  Future<void> answer(ContentDetailCubit cubit, {bool all = true}) async {
    cubit.questionChanged(1, 0, 'Answer 1');
    if (all) cubit.questionChanged(1, 1, 'Answer 2');
  }

  group('load', () {
    test('logs engagement_viewed and loads content without completion',
        () async {
      final cubit = build();
      await cubit.load();

      expect(analytics.names, [AnalyticsEvents.engagementViewed]);
      final s = cubit.state;
      expect(s.status, LoadStatus.success);
      expect(s.content, _content);
      expect(s.completionId, '');
      expect(s.isComplete, isFalse);
      expect(s.responses.isEmpty, isTrue);
      expect(completions.calls, isNot(contains('getResponses')));
      await cubit.close();
    });

    test('loads a completion with its text and image responses', () async {
      completions.completions[_contentId] =
          buildCompletion(_contentId, id: 'comp-1');
      completions.responses['comp-1'] = Responses(id: 'resp-1', responses: {
        '1': {'0': _text('A1'), '1': _text('A2')},
        '2': {
          '0': const ResponseDetails(
              type: ResponseType.image, response: _imageLocation),
        },
      });

      final cubit = build();
      await cubit.load();

      final s = cubit.state;
      expect(s.isComplete, isTrue);
      expect(s.completionId, 'comp-1');
      expect(s.responses.id, 'resp-1');
      expect(s.responses.at(1, 1)?.response, 'A2');
      expect(s.imageUrls, {
        '2': ['https://download/$_imageLocation']
      });
      expect(s.thumbnailUrls, {
        '2': ['https://download/$_thumbLocation']
      });
      await cubit.close();
    });

    test('a draft completion is loaded as not complete', () async {
      completions.completions[_contentId] =
          buildCompletion(_contentId, id: 'comp-1', isDraft: true);
      final cubit = build();
      await cubit.load();
      expect(cubit.state.isComplete, isFalse);
      expect(cubit.state.completionId, 'comp-1');
      await cubit.close();
    });

    test('failure reports the user-safe message', () async {
      final cubit = build(contentId: 'missing');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.errorMessage, 'Content not found');
      await cubit.close();
    });
  });

  group('complete', () {
    test('with no responses shows the noResponses dialog and writes nothing',
        () async {
      final cubit = await loaded();
      await cubit.complete();

      expect(cubit.state.effect, ContentDetailEffect.noResponses);
      expect(cubit.state.isComplete, isFalse);
      expect(completions.calls, isEmpty);
      expect(analytics.events, isEmpty);
      expect(changes, isEmpty);
      await cubit.close();
    });

    test('with partially filled responses saves a draft', () async {
      final cubit = await loaded();
      await answer(cubit, all: false);
      await cubit.complete();

      expect(cubit.state.effect, ContentDetailEffect.savedAsDraft);
      expect(cubit.state.isComplete, isFalse);
      final stored = completions.completions[_contentId]!;
      expect(stored.isDraft, isTrue);
      expect(cubit.state.completionId, stored.id);
      expect(completions.responses[stored.id]?.at(1, 0)?.response, 'Answer 1');
      expect(cubit.state.responses.id, isNotNull);
      expect(analytics.names, isNot(contains('engagement_completed')));
      expect(changes.single.contentId, _contentId);
      expect(changes.single.seriesId, _seriesId);
      await cubit.close();
    });

    test('with all questions answered marks complete and logs', () async {
      final cubit = await loaded();
      await answer(cubit);
      await cubit.complete();

      final stored = completions.completions[_contentId]!;
      expect(stored.isDraft, isFalse);
      expect(stored.isOnTime, isTrue);
      expect(stored.seriesId, _seriesId);
      expect(stored.completionDate, now);
      expect(cubit.state.isComplete, isTrue);
      expect(cubit.state.completionId, stored.id);
      expect(completions.responses[stored.id]?.at(1, 1)?.response, 'Answer 2');
      expect(cubit.state.responses.id, completions.responses[stored.id]?.id);
      expect(analytics.names, [AnalyticsEvents.engagementCompleted]);
      expect(changes, hasLength(1));
      expect(cubit.state.effect, isNull);
      await cubit.close();
    });

    test('completing after the content day is recorded as late', () async {
      now = DateTime(2026, 3, 5, 10);
      final cubit = await loaded();
      await answer(cubit);
      await cubit.complete();
      expect(completions.completions[_contentId]!.isOnTime, isFalse);
      await cubit.close();
    });

    test('completing an existing draft updates it instead of creating',
        () async {
      completions.completions[_contentId] =
          buildCompletion(_contentId, id: 'draft-1', isDraft: true);
      final cubit = await loaded();
      await answer(cubit);
      await cubit.complete();

      expect(completions.calls, contains('updateComplete'));
      expect(completions.calls, isNot(contains('markAsComplete')));
      expect(completions.completions[_contentId]!.id, 'draft-1');
      expect(completions.completions[_contentId]!.isDraft, isFalse);
      expect(cubit.state.isComplete, isTrue);
      await cubit.close();
    });

    test('content without questions is completed directly', () async {
      final cubit = await loaded(contentId: 'read-only');
      await cubit.complete();
      expect(cubit.state.isComplete, isTrue);
      expect(completions.completions['read-only']?.isDraft, isFalse);
      expect(analytics.names, [AnalyticsEvents.engagementCompleted]);
      await cubit.close();
    });

    test('is a no-op when already complete', () async {
      completions.completions['read-only'] = buildCompletion('read-only');
      final cubit = await loaded(contentId: 'read-only');
      await cubit.complete();
      expect(completions.calls, isEmpty);
      expect(analytics.events, isEmpty);
      await cubit.close();
    });

    test('failure surfaces an actionError effect and stays incomplete',
        () async {
      completions.failOn('markAsComplete');
      final cubit = await loaded();
      await answer(cubit);
      await cubit.complete();

      expect(cubit.state.effect, ContentDetailEffect.actionError);
      expect(cubit.state.actionError, 'Fake failure');
      expect(cubit.state.isComplete, isFalse);
      expect(analytics.events, isEmpty);
      expect(changes, isEmpty);
      await cubit.close();
    });

    test('each effect gets a new effectId', () async {
      final cubit = await loaded();
      await cubit.complete();
      final first = cubit.state.effectId;
      await cubit.complete();
      expect(cubit.state.effectId, isNot(first));
      await cubit.close();
    });
  });

  group('undo / editing', () {
    test('undoComplete deletes the completion and notifies', () async {
      completions.completions[_contentId] =
          buildCompletion(_contentId, id: 'comp-1');
      completions.responses['comp-1'] = Responses(id: 'r', responses: {
        '1': {'0': _text('A1'), '1': _text('A2')},
      });
      final cubit = await loaded();
      await cubit.undoComplete();

      expect(completions.incompleted.single,
          (completionId: 'comp-1', isResponsePossible: true));
      expect(completions.completions, isEmpty);
      expect(cubit.state.isComplete, isFalse);
      expect(cubit.state.completionId, '');
      expect(changes, hasLength(1));
      await cubit.close();
    });

    test('undoComplete without responses does not delete responses', () async {
      completions.completions['read-only'] =
          buildCompletion('read-only', id: 'comp-2');
      final cubit = await loaded(contentId: 'read-only');
      await cubit.undoComplete();
      expect(completions.incompleted.single.isResponsePossible, isFalse);
      await cubit.close();
    });

    test('editing an answer of completed content makes it incomplete',
        () async {
      completions.completions[_contentId] =
          buildCompletion(_contentId, id: 'comp-1');
      completions.responses['comp-1'] = Responses(id: 'r', responses: {
        '1': {'0': _text('A1'), '1': _text('A2')},
      });
      final cubit = await loaded();
      cubit.questionChanged(1, 0, 'Changed');
      await pumpEventQueue();

      expect(cubit.state.responses.at(1, 0)?.response, 'Changed');
      expect(completions.incompleted.single.completionId, 'comp-1');
      expect(cubit.state.isComplete, isFalse);
      expect(cubit.state.completionId, '');
      await cubit.close();
    });

    test('editing an incomplete answer does not touch the store', () async {
      final cubit = await loaded();
      cubit.questionChanged(1, 0, 'x');
      await pumpEventQueue();
      expect(completions.calls, isEmpty);
      await cubit.close();
    });
  });

  group('requestExit', () {
    test('is blocked while an image uploads', () async {
      final cubit = await loaded();
      final upload = cubit.uploadImage(2, buildImage());
      await pumpEventQueue();
      expect(cubit.state.isUploading, isTrue);

      expect(cubit.requestExit(), isFalse);
      expect(cubit.state.effect, ContentDetailEffect.uploadInProgress);
      expect(completions.calls, isNot(contains('markAsComplete')));

      completions.nextUpload.finish(_imageLocation);
      await upload;
      await cubit.close();
    });

    test('with responses saves a draft and allows exit', () async {
      final cubit = await loaded();
      await answer(cubit, all: false);

      expect(cubit.requestExit(), isTrue);
      await pumpEventQueue();

      final stored = completions.completions[_contentId]!;
      expect(stored.isDraft, isTrue);
      expect(completions.responses[stored.id]?.at(1, 0)?.response, 'Answer 1');
      expect(changes, hasLength(1));
      await cubit.close();
    });

    test('of completed content does not downgrade it to a draft', () async {
      completions.completions[_contentId] =
          buildCompletion(_contentId, id: 'comp-1');
      completions.responses['comp-1'] = Responses(id: 'r', responses: {
        '1': {'0': _text('A1'), '1': _text('A2')},
      });
      final cubit = await loaded();

      expect(cubit.requestExit(), isTrue);
      await pumpEventQueue();
      expect(completions.calls, isEmpty);
      expect(completions.completions[_contentId]!.isDraft, isFalse);
      await cubit.close();
    });

    test('with emptied responses removes the existing draft', () async {
      completions.completions[_contentId] =
          buildCompletion(_contentId, id: 'draft-1', isDraft: true);
      completions.responses['draft-1'] = Responses(id: 'r', responses: {
        '1': {'0': _text('A1')},
      });
      final cubit = await loaded();
      cubit.questionChanged(1, 0, '');

      expect(cubit.requestExit(), isTrue);
      await pumpEventQueue();
      expect(completions.incompleted.single.completionId, 'draft-1');
      expect(completions.completions, isEmpty);
      await cubit.close();
    });

    test('with nothing entered writes nothing', () async {
      final cubit = await loaded();
      expect(cubit.requestExit(), isTrue);
      await pumpEventQueue();
      expect(completions.calls, isEmpty);
      await cubit.close();
    });
  });

  group('images', () {
    test('uploadImage exposes progress, then stores the response', () async {
      final cubit = await loaded();
      final image = buildImage('pic.png');
      final upload = cubit.uploadImage(2, image);
      await pumpEventQueue();

      expect(cubit.state.isUploading, isTrue);
      final handle = cubit.state.uploads['2']!;
      final progress = <int>[];
      handle.progress.map((p) => p.percent).listen(progress.add);
      completions.nextUpload
        ..emitProgress(25, 100)
        ..emitProgress(100, 100);
      await pumpEventQueue();
      expect(progress, [25, 100]);

      completions.nextUpload.finish(_imageLocation);
      await upload;

      final s = cubit.state;
      expect(s.isUploading, isFalse);
      expect(
          s.responses.at(2, 0),
          const ResponseDetails(
              type: ResponseType.image, response: _imageLocation));
      expect(s.imageUrls['2'], ['https://download/$_imageLocation']);
      expect(s.localImages['2'], [image]);
      expect(s.isComplete, isFalse);
      expect(changes, hasLength(1));
      expect(completions.calls, isNot(contains('markAsIncomplete')));
      await cubit.close();
    });

    test('uploadImage on completed content marks it incomplete', () async {
      completions.completions[_contentId] =
          buildCompletion(_contentId, id: 'comp-1');
      final cubit = await loaded();
      final upload = cubit.uploadImage(2, buildImage());
      completions.nextUpload.finish(_imageLocation);
      await upload;

      expect(completions.incompleted.single,
          (completionId: 'comp-1', isResponsePossible: true));
      expect(cubit.state.completionId, '');
      expect(cubit.state.isComplete, isFalse);
      await cubit.close();
    });

    test('uploadImage failure clears the upload and reports an error',
        () async {
      final cubit = await loaded();
      final upload = cubit.uploadImage(2, buildImage());
      completions.nextUpload.fail();
      await upload;

      expect(cubit.state.isUploading, isFalse);
      expect(cubit.state.effect, ContentDetailEffect.actionError);
      expect(cubit.state.actionError, 'Fake failure');
      expect(cubit.state.responses.isEmpty, isTrue);
      expect(changes, isEmpty);
      await cubit.close();
    });

    test('deleteImage removes the files and the response', () async {
      completions.completions[_contentId] =
          buildCompletion(_contentId, id: 'comp-1');
      completions.responses['comp-1'] = const Responses(id: 'r', responses: {
        '2': {
          '0': ResponseDetails(
              type: ResponseType.image, response: _imageLocation),
        },
      });
      final cubit = await loaded();
      expect(cubit.state.imageUrls['2'], isNotEmpty);

      await cubit.deleteImage(2);
      await pumpEventQueue();

      expect(completions.deletedImages,
          unorderedEquals([_imageLocation, _thumbLocation]));
      final s = cubit.state;
      expect(s.responses.at(2, 0), isNull);
      expect(s.imageUrls.containsKey('2'), isFalse);
      expect(s.thumbnailUrls.containsKey('2'), isFalse);
      expect(completions.incompleted.single.completionId, 'comp-1');
      expect(s.completionId, '');
      expect(s.isComplete, isFalse);
      expect(changes, hasLength(1));
      await cubit.close();
    });

    test('deleteImage of a just-uploaded image', () async {
      final cubit = await loaded();
      final upload = cubit.uploadImage(2, buildImage());
      completions.nextUpload.finish(_imageLocation);
      await upload;

      await cubit.deleteImage(2);
      await pumpEventQueue();
      expect(cubit.state.responses.isEmpty, isTrue);
      expect(cubit.state.localImages.containsKey('2'), isFalse);
      expect(completions.deletedImages, contains(_imageLocation));
      await cubit.close();
    });

    test('deleteImage without an image is a no-op', () async {
      final cubit = await loaded();
      await cubit.deleteImage(2);
      expect(completions.calls, isEmpty);
      await cubit.close();
    });

    test('deleteImage tolerates storage delete failures', () async {
      completions.failOn('deleteImage');
      final cubit = await loaded();
      final upload = cubit.uploadImage(2, buildImage());
      completions.nextUpload.finish(_imageLocation);
      await upload;

      await cubit.deleteImage(2);
      await pumpEventQueue();
      expect(cubit.state.responses.isEmpty, isTrue);
      expect(cubit.state.effect, isNot(ContentDetailEffect.actionError));
      await cubit.close();
    });
  });

  test('state equality ignores upload handle identity', () {
    final a = ContentDetailState(uploads: {'2': FakeUploadHandle()});
    final b = ContentDetailState(uploads: {'2': FakeUploadHandle()});
    expect(a, b);
    expect(a.isUploading, isTrue);
    expect(
        const ContentDetailState().uploads, isA<Map<String, UploadHandle>>());
  });

  group('audio', () {
    final listen = SeriesContent(
      id: 'listen',
      contentType: 'LISTEN',
      date: DateTime(2026, 3, 2),
      title: 'Day 2',
      subTitle: '',
      body: const [
        AudioBody(audioFileUrl: 'https://example.com/a.mp3', title: 'Sermon'),
        AudioBody(audioFileUrl: 'https://example.com/b.mp3', title: ''),
      ],
    );

    setUp(() {
      bibleSeries
        ..contents['listen'] = listen
        ..seriesById[_seriesId] = buildSeries(id: _seriesId, days: []);
    });

    test('loads the series for lock-screen metadata when there is audio',
        () async {
      final cubit = await loaded(contentId: 'listen');
      await pumpEventQueue();

      expect(cubit.state.series?.id, _seriesId);
      final track = cubit.audioTrackFor(0, listen.body[0] as AudioBody);
      expect(
        track,
        const AudioTrack(
          id: 'listen/0',
          url: 'https://example.com/a.mp3',
          title: 'Sermon',
          subtitle: 'Day 2 · Series $_seriesId',
          artworkUrl: 'https://img/$_seriesId',
          origin: AudioTrackOrigin(
            seriesId: _seriesId,
            contentId: 'listen',
            contentType: 'LISTEN',
          ),
        ),
      );
      await cubit.close();
    });

    test('an untitled audio body is titled by the content', () async {
      final cubit = await loaded(contentId: 'listen');
      await pumpEventQueue();
      final track = cubit.audioTrackFor(1, listen.body[1] as AudioBody);
      expect(track.id, 'listen/1');
      expect(track.title, 'Day 2');
      expect(track.subtitle, 'Series $_seriesId');
      await cubit.close();
    });

    test('without the series, audio still has a track (no artwork)', () async {
      bibleSeries.seriesById.clear();
      final cubit = await loaded(contentId: 'listen');
      await pumpEventQueue();
      final track = cubit.audioTrackFor(0, listen.body[0] as AudioBody);
      expect(track.artworkUrl, isNull);
      expect(track.subtitle, 'Day 2');
      expect(cubit.state.status, LoadStatus.success);
      await cubit.close();
    });

    test('content without audio does not load the series', () async {
      final cubit = await loaded();
      await pumpEventQueue();
      expect(bibleSeries.calls, isNot(contains('getBibleSeriesDetails')));
      await cubit.close();
    });
  });

  group('scripture', () {
    const john = BiblePassage(
      id: 'JHN.3.16-JHN.3.17',
      reference: 'John 3:16-17',
      content: '[16] For God so loved the world [17] For God did not send',
    );
    const psalm = BiblePassage(
      id: 'PSA.23.1',
      reference: 'Psalm 23:1',
      content: '[1] The Lord is my shepherd',
    );
    final read = SeriesContent(
      id: 'read',
      contentType: 'READ',
      date: DateTime(2026, 3, 2),
      title: 'Day 2',
      subTitle: '',
      body: const [
        ScriptureBody(passageIds: ['JHN.3.16-JHN.3.17', 'PSA.23.1']),
        TextBody(paragraphs: ['Between']),
        ScriptureBody(passageIds: ['PSA.23.1']),
      ],
    );

    setUp(() => bibleSeries.contents['read'] = read);

    test('content is shown first, then every passage is loaded once', () async {
      passages.passages
        ..[john.id] = john
        ..[psalm.id] = psalm;
      final cubit = build(contentId: 'read');
      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      await pumpEventQueue();
      expect(cubit.state.passages, {
        john.id: const PassageLoad.loaded(john),
        psalm.id: const PassageLoad.loaded(psalm),
      });
      expect(passages.callCount('getPassage'), 2);
      await cubit.close();
    });

    test('a failed passage does not fail the content and can be retried',
        () async {
      passages.passages[john.id] = john;
      final cubit = build(contentId: 'read');
      await cubit.load();
      await pumpEventQueue();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.passages[john.id], const PassageLoad.loaded(john));
      expect(cubit.state.passages[psalm.id], const PassageLoad.failed());

      passages.passages[psalm.id] = psalm;
      final retry = cubit.retryPassage(psalm.id);
      expect(cubit.state.passages[psalm.id], const PassageLoad.loading());
      await retry;
      expect(cubit.state.passages[psalm.id], const PassageLoad.loaded(psalm));
      await cubit.close();
    });

    test('content without scripture loads no passages', () async {
      final cubit = await loaded();
      await pumpEventQueue();
      expect(cubit.state.passages, isEmpty);
      expect(passages.calls, isEmpty);
      await cubit.close();
    });
  });
}
