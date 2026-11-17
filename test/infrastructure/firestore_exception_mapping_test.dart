import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/notification_settings/entities.dart';
import 'package:wpa_app/domain/prayer_requests/exceptions.dart';
import 'package:wpa_app/infrastructure/forum/forum_repository.dart';
import 'package:wpa_app/infrastructure/notification_settings/notification_settings_service.dart';
import 'package:wpa_app/infrastructure/prayer_requests/prayer_requests_repository.dart';
import 'package:wpa_app/infrastructure/user_profile/user_profile_repository.dart';
import 'package:wpa_app/services/firebase_firestore_service.dart';

import '_support/fakes.dart';

final throwsPermissionDenied = throwsA(isA<DatabaseException>()
    .having((e) => e.code, 'code', DatabaseExceptionCode.permissionDenied)
    .having((e) => e.message, 'message',
        'You do not have permission to execute this operation'));

void main() {
  group('FirebaseFirestoreService.handleException', () {
    const service = FirebaseFirestoreService();

    test('permission-denied maps to DatabaseException(permissionDenied)', () {
      final error = firestoreError('permission-denied');
      final mapped = service.handleException(error);
      expect(
        mapped,
        isA<DatabaseException>()
            .having(
                (e) => e.code, 'code', DatabaseExceptionCode.permissionDenied)
            .having((e) => e.details, 'details', same(error)),
      );
    });

    test('other Firebase errors map to an unknown ApplicationException', () {
      final mapped = service.handleException(firestoreError('unavailable'));
      expect(
        mapped,
        isA<ApplicationException>()
            .having((e) => e.code, 'code', ApplicationExceptionCode.unknown)
            .having((e) => e.message, 'message', kUnknownErrorMessage),
      );
    });

    test('domain exceptions pass through unchanged', () {
      const domain = PrayerRequestsException(
        code: PrayerRequestsExceptionCode.alreadyReported,
        message: 'x',
      );
      expect(service.handleException(domain), same(domain));
    });
  });

  group('repositories throw mapped Firestore failures (B4)', () {
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
          const FirebaseFirestoreService(),
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
        throwsA(isA<ApplicationException>()),
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
        const FirebaseFirestoreService(),
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
        const FirebaseFirestoreService(),
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
      final repository =
          ForumRepository(firestore, const FirebaseFirestoreService());

      await expectLater(
        repository.freezeThread('th1', 'forum-1', true),
        throwsPermissionDenied,
      );
      await expectLater(
        repository.watchThreads('forum-1'),
        emitsError(isA<DatabaseException>().having(
            (e) => e.code, 'code', DatabaseExceptionCode.permissionDenied)),
      );
    });
  });
}
