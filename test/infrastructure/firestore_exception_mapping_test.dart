import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/domain/common/error_reporting.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/notification_settings/entities.dart';
import 'package:wpa_app/domain/prayer_requests/exceptions.dart';
import 'package:wpa_app/infrastructure/common/firebase_error_translator.dart';
import 'package:wpa_app/infrastructure/forum/forum_repository.dart';
import 'package:wpa_app/infrastructure/notification_settings/notification_settings_service.dart';
import 'package:wpa_app/infrastructure/prayer_requests/prayer_requests_repository.dart';
import 'package:wpa_app/infrastructure/user_profile/user_profile_repository.dart';

import '_support/fakes.dart';

/// The original Firebase error reaches the caller: not swallowed (B4) and
/// not replaced, so its details and stack trace are kept for reporting.
final throwsPermissionDenied = throwsA(isA<FirebaseException>()
    .having((e) => e.code, 'code', 'permission-denied'));

void main() {
  group('translateFirebaseError', () {
    test('permission-denied becomes DatabaseException(permissionDenied)', () {
      final error = firestoreError('permission-denied');
      expect(
        translateFirebaseError(error),
        isA<DatabaseException>()
            .having(
                (e) => e.code, 'code', DatabaseExceptionCode.permissionDenied)
            .having((e) => e.message, 'message',
                'You do not have permission to execute this operation')
            .having((e) => e.details, 'details', same(error)),
      );
    });

    test('other errors are not recognised', () {
      expect(translateFirebaseError(firestoreError('unavailable')), isNull);
      expect(translateFirebaseError(StateError('x')), isNull);
    });
  });

  group('userMessageFor with the Firebase translator', () {
    final recorded = <(Object, StackTrace?)>[];

    setUp(() {
      recorded.clear();
      ErrorHooks.install(
        translate: translateFirebaseError,
        record: (e, st) => recorded.add((e, st)),
      );
    });

    tearDown(ErrorHooks.reset);

    test('a permission error gets its message and is recorded with its trace',
        () {
      final error = firestoreError('permission-denied');
      final trace = StackTrace.current;

      expect(userMessageFor(error, stackTrace: trace),
          'You do not have permission to execute this operation');
      expect(recorded.single.$1, same(error));
      expect(recorded.single.$2, same(trace));
    });

    test('an unrecognised error gets the fallback and is recorded', () {
      expect(
          userMessageFor(firestoreError('unavailable')), kUnknownErrorMessage);
      expect(recorded, hasLength(1));
    });

    test('expected app exceptions keep their message and are not recorded', () {
      const domain = PrayerRequestsException(
        code: PrayerRequestsExceptionCode.alreadyReported,
        message: 'already',
      );
      expect(userMessageFor(domain), 'already');
      expect(recorded, isEmpty);
    });

    test('app exceptions wrapping a cause are recorded', () {
      final wrapped = StorageException(
        code: StorageExceptionCode.unknown,
        message: 'upload failed',
        details: firestoreError('unavailable'),
      );
      expect(userMessageFor(wrapped), 'upload failed');
      expect(recorded.single.$1, same(wrapped));
    });

    test('reportError records only unexpected errors', () {
      reportError(StateError('boom'));
      reportError(const PrayerRequestsException(
        code: PrayerRequestsExceptionCode.alreadyReported,
        message: 'x',
      ));
      expect(recorded.map((r) => r.$1), [isA<StateError>()]);
    });
  });

  group('repositories propagate Firestore failures (B4)', () {
    late MockFirebaseFirestore firestore;
    late MockCollectionReference collection;
    late MockDocumentReference document;
    late MockQuery query;

    setUp(() {
      firestore = MockFirebaseFirestore();
      collection = MockCollectionReference();
      document = MockDocumentReference();
      query = MockQuery();
      when(() => firestore.collection(any())).thenReturn(collection);
      when(() => collection.doc(any())).thenReturn(document);
      when(() => collection.where(any(), isEqualTo: any(named: 'isEqualTo')))
          .thenReturn(query);
      when(() => query.where(any(), isEqualTo: any(named: 'isEqualTo')))
          .thenReturn(query);
      when(() => query.orderBy(any(), descending: any(named: 'descending')))
          .thenReturn(query);
      when(() => query.limit(any())).thenReturn(query);
    });

    PrayerRequestsRepository prayerRequests() => PrayerRequestsRepository(
          firestore,
          createStorageMock(),
          sessionWith(),
        );

    test('prayer request paging: query failure', () async {
      when(() => query.get()).thenThrow(firestoreError('permission-denied'));

      await expectLater(
        prayerRequests().getPrayerRequests(limit: 10),
        throwsPermissionDenied,
      );
    });

    test('prayer request paging: unknown failure is thrown, not swallowed',
        () async {
      when(() => query.get()).thenThrow(firestoreError('unavailable'));

      await expectLater(
        prayerRequests().getPrayerRequests(limit: 10),
        throwsA(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'unavailable')),
      );
    });

    test('prayer request create: add failure', () async {
      when(() => collection.add(any()))
          .thenThrow(firestoreError('permission-denied'));

      await expectLater(
        prayerRequests().createPrayerRequest(request: 'r', isAnonymous: false),
        throwsPermissionDenied,
      );
    });

    test('prayer request delete: delete failure', () async {
      when(() => document.delete())
          .thenThrow(firestoreError('permission-denied'));

      await expectLater(
        prayerRequests().deletePrayerRequest(id: 'p1'),
        throwsPermissionDenied,
      );
    });

    test('profile photo update failure', () async {
      when(() => document.update(any()))
          .thenThrow(firestoreError('permission-denied'));
      final repository = UserProfileRepository(
        firestore,
        createStorageMock(),
        MockAuthenticationFacade(),
        sessionWith(),
      );

      await expectLater(
        repository.setProfilePhoto(profilePhoto: 'p', thumbnail: 't'),
        throwsPermissionDenied,
      );
    });

    test('notification settings read failure', () async {
      final settings = MockCollectionReference();
      when(() => document.collection('notification_settings'))
          .thenReturn(settings);
      when(() => settings.get()).thenThrow(firestoreError('permission-denied'));
      final service = NotificationSettingsService(
        firestore,
        sessionWith(),
      );

      await expectLater(
          service.getNotificationSettings(), throwsPermissionDenied);
      await expectLater(
        service.setSetting(NotificationSetting.prayers, true),
        throwsPermissionDenied,
      );
    });

    test('forum write and stream failures', () async {
      final threads = MockCollectionReference();
      when(() => document.collection('threads')).thenReturn(threads);
      when(() => threads.doc(any())).thenReturn(document);
      when(() => threads.orderBy(any(), descending: any(named: 'descending')))
          .thenReturn(query);
      when(() => document.update(any()))
          .thenThrow(firestoreError('permission-denied'));
      when(() => query.snapshots())
          .thenAnswer((_) => Stream.error(firestoreError('permission-denied')));
      final repository = ForumRepository(firestore);

      await expectLater(
        repository.freezeThread('th1', 'forum-1', true),
        throwsPermissionDenied,
      );
      await expectLater(
        repository.watchThreads('forum-1'),
        emitsError(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'permission-denied')),
      );
    });
  });
}
