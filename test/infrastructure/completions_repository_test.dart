import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/common/media_upload.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/domain/completions/exceptions.dart';
import 'package:wpa_app/infrastructure/completions/completions_repository.dart';
import 'package:wpa_app/services/firebase_firestore_service.dart';

import '_support/fakes.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseStorageService storage;
  late CompletionsRepository repository;

  CollectionReference<Map<String, dynamic>> completions() =>
      firestore.collection('completions');

  CollectionReference<Map<String, dynamic>> responsesOf(String id) =>
      completions().doc(id).collection('responses');

  setUpAll(() => registerFallbackValue(FakeImageData()));

  setUp(() {
    firestore = FakeFirebaseFirestore();
    storage = createStorageMock();
    repository = CompletionsRepository(
      firestore,
      const FirebaseFirestoreService(),
      storage,
      sessionWith(),
    );
  });

  group('completions', () {
    test('markAsComplete writes the exact pre-refactor document', () async {
      final id = await repository.markAsComplete(
        completionDetails: CompletionDetails(
          id: '',
          seriesId: 'series-1',
          contentId: 'content-1',
          isOnTime: true,
          isDraft: false,
          completionDate: day(4),
        ),
      );

      expect((await completions().doc(id).get()).data(), {
        'is_draft': false,
        'content_id': 'content-1',
        'is_on_time': true,
        'series_id': 'series-1',
        'completion_date': ts(4),
        'user_id': 'user-1',
      });
    });

    test('a draft is written with a null completion_date', () async {
      final id = await repository.markAsComplete(
        completionDetails: const CompletionDetails(
          id: '',
          seriesId: 'series-1',
          contentId: 'content-2',
          isOnTime: false,
          isDraft: true,
        ),
      );

      expect((await completions().doc(id).get()).data(), {
        'is_draft': true,
        'content_id': 'content-2',
        'is_on_time': false,
        'series_id': 'series-1',
        'completion_date': null,
        'user_id': 'user-1',
      });
    });

    test('updateComplete updates only draft / on-time / date', () async {
      await completions().doc('c1').set({
        'is_draft': true,
        'content_id': 'content-1',
        'is_on_time': false,
        'series_id': 'series-1',
        'completion_date': null,
        'user_id': 'user-1',
      });

      final id = await repository.updateComplete(
        completionId: 'c1',
        completionDetails: CompletionDetails(
          id: 'c1',
          seriesId: 'ignored',
          contentId: 'ignored',
          isOnTime: true,
          isDraft: false,
          completionDate: day(6),
        ),
      );

      expect(id, 'c1');
      expect((await completions().doc('c1').get()).data(), {
        'is_draft': false,
        'content_id': 'content-1',
        'is_on_time': true,
        'series_id': 'series-1',
        'completion_date': ts(6),
        'user_id': 'user-1',
      });
    });

    test('getAllCompletions returns my completions of a series by content id',
        () async {
      await completions().doc('c1').set({
        'is_draft': false,
        'content_id': 'content-1',
        'is_on_time': true,
        'series_id': 'series-1',
        'completion_date': ts(2),
        'user_id': 'user-1',
      });
      await completions().doc('c2').set({
        'is_draft': true,
        'content_id': 'content-2',
        'is_on_time': false,
        'series_id': 'series-1',
        'completion_date': null,
        'user_id': 'user-1',
      });
      await completions().doc('other-series').set({
        'is_draft': false,
        'content_id': 'content-3',
        'is_on_time': true,
        'series_id': 'series-2',
        'completion_date': ts(2),
        'user_id': 'user-1',
      });
      await completions().doc('other-user').set({
        'is_draft': false,
        'content_id': 'content-1',
        'is_on_time': true,
        'series_id': 'series-1',
        'completion_date': ts(2),
        'user_id': 'someone-else',
      });

      final result =
          await repository.getAllCompletions(bibleSeriesId: 'series-1');

      expect(result, {
        'content-1': CompletionDetails(
          id: 'c1',
          seriesId: 'series-1',
          contentId: 'content-1',
          isOnTime: true,
          isDraft: false,
          completionDate: day(2),
        ),
        'content-2': const CompletionDetails(
          id: 'c2',
          seriesId: 'series-1',
          contentId: 'content-2',
          isOnTime: false,
          isDraft: true,
        ),
      });
    });

    test('getCompletionOrNull returns null when there is none', () async {
      expect(
        await repository.getCompletionOrNull(seriesContentId: 'content-1'),
        isNull,
      );
    });

    test('markAsIncomplete deletes the completion document', () async {
      await completions().doc('c1').set({'user_id': 'user-1'});
      await completions().doc('c2').set({'user_id': 'user-1'});

      await repository.markAsIncomplete(
          completionId: 'c1', isResponsePossible: true);

      // The response clean-up cannot be asserted with fake_cloud_firestore:
      // deleting a document there also hides its sub-collections from
      // queries (real Firestore keeps them), so the repository's follow-up
      // `responses` query sees nothing.
      expect((await completions().doc('c1').get()).exists, isFalse);
      expect((await completions().doc('c2').get()).exists, isTrue);
    });
  });

  group('responses', () {
    const responses = Responses(responses: {
      '0': {
        '0': ResponseDetails(type: ResponseType.text, response: 'An answer'),
        '1': ResponseDetails(
            type: ResponseType.image, response: 'gs://bucket/r/1.jpg'),
      },
      '3': {
        '0': ResponseDetails(type: ResponseType.text, response: 'Another'),
      },
    });

    const expectedDocument = {
      'user_id': 'user-1',
      'responses': {
        '0': {
          '0': {'response': 'An answer', 'type': 'text'},
          '1': {'response': 'gs://bucket/r/1.jpg', 'type': 'image'},
        },
        '3': {
          '0': {'response': 'Another', 'type': 'text'},
        },
      },
    };

    test('putResponses without an id adds the exact response document',
        () async {
      final id = await repository.putResponses(
          completionId: 'c1', responses: responses);

      expect((await responsesOf('c1').doc(id).get()).data(), expectedDocument);
    });

    test('putResponses with an id overwrites that document', () async {
      await responsesOf('c1').doc('r1').set({
        'user_id': 'user-1',
        'responses': {
          '9': {
            '9': {'response': 'stale', 'type': 'text'},
          },
        },
        'extra': 'dropped by set()',
      });

      final id = await repository.putResponses(
          completionId: 'c1', responses: responses.withId('r1'));

      expect(id, 'r1');
      expect((await responsesOf('c1').get()).docs, hasLength(1));
      expect(
          (await responsesOf('c1').doc('r1').get()).data(), expectedDocument);
    });

    test('getResponses reads the stored shape back into Responses', () async {
      await responsesOf('c1').doc('r1').set(expectedDocument);
      await responsesOf('c1').doc('r2').set({
        'user_id': 'other',
        'responses': <String, dynamic>{},
      });

      expect(await repository.getResponses(completionId: 'c1'),
          responses.withId('r1'));
    });

    test('getResponses returns empty Responses when there are none', () async {
      final result = await repository.getResponses(completionId: 'c1');
      expect(result.isEmpty, isTrue);
      expect(result.id, isNull);
    });
  });

  group('images', () {
    final image = ImageData(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'photo.jpg',
    );

    test('uploadImage uploads under /responses/<uid>/ with the extension', () {
      final handle = MockUploadHandle();
      when(() => storage.startUpload(any(), any())).thenReturn(handle);

      expect(repository.uploadImage(image: image), same(handle));

      final path = verify(() => storage.startUpload(captureAny(), image))
          .captured
          .single as String;
      expect(path, startsWith('/responses/user-1/'));
      expect(path, endsWith('.jpg'));
    });

    test('uploadImage failures are thrown as CompletionsException', () {
      when(() => storage.startUpload(any(), any())).thenThrow(
        const StorageException(
          code: StorageExceptionCode.unableToStartUpload,
          message: 'no',
        ),
      );

      expect(
        () => repository.uploadImage(image: image),
        throwsA(isA<CompletionsException>().having((e) => e.code, 'code',
            CompletionsExceptionCode.unableToUploadImage)),
      );
    });

    test('deleteImage failures are thrown, not discarded', () async {
      when(() => storage.deleteFile(any())).thenThrow(Exception('boom'));

      await expectLater(
        repository.deleteImage(gsUrl: 'gs://bucket/x.jpg'),
        throwsA(isA<CompletionsException>()),
      );
    });
  });
}
