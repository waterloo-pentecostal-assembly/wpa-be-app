import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/authentication/exceptions.dart';
import 'package:wpa_app/domain/authentication/value_objects.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/infrastructure/authentication/firebase_authentication_facade.dart';
import 'package:wpa_app/infrastructure/session/app_session.dart';
import 'package:wpa_app/services/firebase_messaging_service.dart';

import '_support/fakes.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockFirebaseMessagingService extends Mock
    implements FirebaseMessagingService {}

final email = EmailAddress('jane@example.com');
final password = Password('password123');

Matcher throwsAuth(AuthenticationExceptionCode code) =>
    throwsA(isA<AuthenticationException>().having((e) => e.code, 'code', code));

final throwsUnknown = throwsA(isA<ApplicationException>()
    .having((e) => e.code, 'code', ApplicationExceptionCode.unknown));

/// `users/{uid}` as written at registration and later verified by an admin.
Map<String, dynamic> userDoc({bool isVerified = true}) => {
      'first_name': 'Jane',
      'last_name': 'Doe',
      'email': 'jane@example.com',
      'reports': 2,
      'is_verified': isVerified,
      'is_admin': true,
      'thumbnail': 'gs://bucket/t.jpg',
      'profile_photo': 'gs://bucket/p.jpg',
    };

void main() {
  late MockFirebaseAuth auth;
  late MockUser user;
  late FakeFirebaseFirestore firestore;
  late MockFirebaseMessagingService messaging;
  late AppSession session;
  late FirebaseAuthenticationFacade facade;

  FirebaseAuthenticationFacade buildFacade(FirebaseFirestore db) =>
      FirebaseAuthenticationFacade(
        auth,
        db,
        createStorageMock(),
        messaging,
        session,
      );

  setUp(() {
    auth = MockFirebaseAuth();
    user = MockUser();
    firestore = FakeFirebaseFirestore();
    messaging = MockFirebaseMessagingService();
    session = AppSession();
    facade = buildFacade(firestore);

    when(() => user.uid).thenReturn('uid-1');
    when(() => user.emailVerified).thenReturn(true);
    when(() => user.sendEmailVerification()).thenAnswer((_) async {});
    when(() => user.delete()).thenAnswer((_) async {});
    when(() => messaging.getToken()).thenAnswer((_) async => 'token-1');
    when(() => messaging.getPlatform()).thenReturn('ios');
  });

  void stubSignIn({Object? error}) {
    final call = when(() => auth.signInWithEmailAndPassword(
        email: any(named: 'email'), password: any(named: 'password')));
    if (error != null) {
      call.thenThrow(error);
    } else {
      call.thenAnswer((_) async => MockUserCredential());
    }
  }

  group('signInWithEmailAndPassword (B4: errors are mapped and thrown)', () {
    const mapped = {
      'invalid-credential': AuthenticationExceptionCode.invalidEmailOrPassword,
      'wrong-password': AuthenticationExceptionCode.invalidEmailOrPassword,
      'invalid-email': AuthenticationExceptionCode.invalidEmailOrPassword,
      'user-not-found': AuthenticationExceptionCode.userNotFound,
      'user-disabled': AuthenticationExceptionCode.userDisabled,
    };

    mapped.forEach((firebaseCode, domainCode) {
      test('$firebaseCode -> ${domainCode.name}', () async {
        stubSignIn(error: FirebaseAuthException(code: firebaseCode));

        await expectLater(
          facade.signInWithEmailAndPassword(
              emailAddress: email, password: password),
          throwsAuth(domainCode),
        );
        expect(session.currentUser, isNull);
      });
    });

    test('an unmapped auth code is thrown as an unknown ApplicationException',
        () async {
      stubSignIn(error: FirebaseAuthException(code: 'too-many-requests'));

      await expectLater(
        facade.signInWithEmailAndPassword(
            emailAddress: email, password: password),
        throwsUnknown,
      );
    });

    test('a non-auth error is thrown as an unknown ApplicationException',
        () async {
      stubSignIn(error: StateError('network'));

      await expectLater(
        facade.signInWithEmailAndPassword(
            emailAddress: email, password: password),
        throwsUnknown,
      );
    });

    test('success loads users/{uid} and publishes it to the session', () async {
      stubSignIn();
      when(() => auth.currentUser).thenReturn(user);
      await firestore.collection('users').doc('uid-1').set(userDoc());

      final result = await facade.signInWithEmailAndPassword(
          emailAddress: email, password: password);

      final expected = LocalUser(
        id: 'uid-1',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        reports: 2,
        thumbnailUrl: downloadUrlFor('gs://bucket/t.jpg'),
        thumbnail: 'gs://bucket/t.jpg',
        profilePhotoUrl: downloadUrlFor('gs://bucket/p.jpg'),
        profilePhoto: 'gs://bucket/p.jpg',
        isAdmin: true,
        isVerified: true,
      );
      expect(result, expected);
      expect(session.currentUser, expected);
    });

    test('a user not yet verified by an admin is rejected', () async {
      stubSignIn();
      when(() => auth.currentUser).thenReturn(user);
      await firestore
          .collection('users')
          .doc('uid-1')
          .set(userDoc(isVerified: false));

      await expectLater(
        facade.signInWithEmailAndPassword(
            emailAddress: email, password: password),
        throwsAuth(AuthenticationExceptionCode.userNotVerified),
      );
      expect(session.currentUser, isNull);
    });

    test('an unverified email address sends a verification email and throws',
        () async {
      stubSignIn();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.emailVerified).thenReturn(false);
      await firestore.collection('users').doc('uid-1').set(userDoc());

      await expectLater(
        facade.signInWithEmailAndPassword(
            emailAddress: email, password: password),
        throwsAuth(AuthenticationExceptionCode.userNotVerified),
      );
      verify(() => user.sendEmailVerification()).called(1);
      expect(session.currentUser, isNull);
    });
  });

  group('getSignedInUser', () {
    test('throws notAuthenticated when signed out', () async {
      when(() => auth.currentUser).thenReturn(null);
      await expectLater(facade.getSignedInUser(),
          throwsAuth(AuthenticationExceptionCode.notAuthenticated));
    });

    test('throws userCollectionNotFound without a user document', () async {
      when(() => auth.currentUser).thenReturn(user);
      await expectLater(facade.getSignedInUser(),
          throwsAuth(AuthenticationExceptionCode.userCollectionNotFound));
    });

    test('a Firestore failure is thrown as the mapped DatabaseException',
        () async {
      final db = MockFirebaseFirestore();
      final users = MockCollectionReference();
      final doc = MockDocumentReference();
      when(() => db.collection('users')).thenReturn(users);
      when(() => users.doc('uid-1')).thenReturn(doc);
      when(() => doc.get()).thenThrow(firestoreError('permission-denied'));
      when(() => auth.currentUser).thenReturn(user);

      await expectLater(
        buildFacade(db).getSignedInUser(),
        throwsA(isA<DatabaseException>().having(
            (e) => e.code, 'code', DatabaseExceptionCode.permissionDenied)),
      );
    });
  });

  group('registerWithEmailAndPassword', () {
    void stubCreate({Object? error}) {
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(user);
      final call = when(() => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'), password: any(named: 'password')));
      if (error != null) {
        call.thenThrow(error);
      } else {
        call.thenAnswer((_) async => credential);
      }
    }

    Future<void> register(FirebaseAuthenticationFacade f) =>
        f.registerWithEmailAndPassword(
          firstName: Name('Jane'),
          lastName: Name('Doe'),
          emailAddress: email,
          password: password,
        );

    test('writes the exact user and notification settings documents', () async {
      stubCreate();

      await register(facade);

      expect((await firestore.collection('users').doc('uid-1').get()).data(), {
        'first_name': 'Jane',
        'last_name': 'Doe',
        'email': 'jane@example.com',
        'reports': 0,
        'is_verified': false,
        'is_admin': false,
      });
      final settings = await firestore
          .collection('users')
          .doc('uid-1')
          .collection('notification_settings')
          .get();
      expect(settings.docs.single.data(), {
        'daily_engagement_reminder': true,
        'testimonies': true,
        'prayers': true,
        'new_prayer_request': true,
        'new_testimony': true,
        'new_forum_thread': true,
        'forum_comment_likes': true,
        'forum_comment_replies': true,
        'forum_thread_comments': true,
      });
      verify(() => auth.createUserWithEmailAndPassword(
          email: 'jane@example.com', password: 'password123')).called(1);
      verifyNever(() => user.sendEmailVerification());
    });

    test('email-already-in-use -> emailInUse', () async {
      stubCreate(error: FirebaseAuthException(code: 'email-already-in-use'));
      await expectLater(
          register(facade), throwsAuth(AuthenticationExceptionCode.emailInUse));
    });

    test('other auth errors are thrown as unknown', () async {
      stubCreate(error: FirebaseAuthException(code: 'weak-password'));
      await expectLater(register(facade), throwsUnknown);
    });

    test('a Firestore failure deletes the auth user and throws mapped',
        () async {
      stubCreate();
      final db = MockFirebaseFirestore();
      final users = MockCollectionReference();
      final doc = MockDocumentReference();
      when(() => db.collection('users')).thenReturn(users);
      when(() => users.doc('uid-1')).thenReturn(doc);
      when(() => doc.set(any())).thenThrow(firestoreError('permission-denied'));

      await expectLater(
        register(buildFacade(db)),
        throwsA(isA<DatabaseException>()),
      );
      verify(() => user.delete()).called(1);
    });
  });

  group('account', () {
    test('sendPasswordResetEmail: user-not-found is thrown', () async {
      when(() => auth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));
      await expectLater(
        facade.sendPasswordResetEmail(emailAddress: email),
        throwsAuth(AuthenticationExceptionCode.userNotFound),
      );
    });

    test('initiateDelete writes the exact deletion request', () async {
      session.update(testUser);

      await facade.initiateDelete('uid-1');

      final requests =
          await firestore.collection('account_deletion_requests').get();
      final data = requests.docs.single.data();
      expect(without(data, ['request_date']), {
        'account_disabled': false,
        'user_data_deleted': false,
        'user_id': 'uid-1',
      });
      expect(data['request_date'], isA<Timestamp>());
      expect(session.currentUser, isNull);
    });
  });

  group('devices', () {
    DocumentReference<Map<String, dynamic>> deviceDoc() => firestore
        .collection('users')
        .doc('uid-1')
        .collection('devices')
        .doc('token-1');

    test('addDeviceToken writes the exact device document', () async {
      expect(await facade.deviceTokenExists('uid-1'), isFalse);

      await facade.addDeviceToken('uid-1');

      final data = (await deviceDoc().get()).data();
      expect(without(data, ['created_at']), {
        'token': 'token-1',
        'platform': 'ios',
      });
      expect(data!['created_at'], isA<Timestamp>());
      expect(await facade.deviceTokenExists('uid-1'), isTrue);
    });

    test('without an FCM token nothing is registered', () async {
      when(() => messaging.getToken()).thenAnswer((_) async => null);

      expect(await facade.deviceTokenExists('uid-1'), isFalse);
      await facade.addDeviceToken('uid-1');

      final devices = await firestore
          .collection('users')
          .doc('uid-1')
          .collection('devices')
          .get();
      expect(devices.docs, isEmpty);
    });

    test('a profile photo that cannot be resolved does not block sign-in',
        () async {
      final storage = createStorageMock();
      when(() => storage.tryGetDownloadUrl(any()))
          .thenAnswer((_) async => null);
      facade = FirebaseAuthenticationFacade(
          auth, firestore, storage, messaging, session);
      await firestore.collection('users').doc('uid-1').set(userDoc());
      when(() => auth.currentUser).thenReturn(user);

      final signedIn = await facade.getSignedInUser();

      expect(signedIn.profilePhoto, 'gs://bucket/p.jpg');
      expect(signedIn.profilePhotoUrl, isNull);
      expect(session.currentUser, signedIn);
    });

    test('signOut removes the device token and clears the session', () async {
      session.update(testUser);
      await deviceDoc().set({'token': 'token-1'});
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.signOut()).thenAnswer((_) async {});

      await facade.signOut();

      expect((await deviceDoc().get()).exists, isFalse);
      expect(session.currentUser, isNull);
      verify(() => auth.signOut()).called(1);
    });
  });
}
