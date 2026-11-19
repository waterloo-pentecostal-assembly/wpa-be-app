import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/domain/common/media_upload.dart';
import 'package:wpa_app/domain/user_profile/exceptions.dart';
import 'package:wpa_app/infrastructure/user_profile/user_profile_repository.dart';

import '_support/fakes.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseStorageService storage;
  late MockAuthenticationFacade facade;
  late UserProfileRepository repository;

  final image = ImageData(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: 'IMG_0001.png',
  );

  setUpAll(() => registerFallbackValue(FakeImageData()));

  setUp(() {
    firestore = FakeFirebaseFirestore();
    storage = createStorageMock();
    facade = MockAuthenticationFacade();
    repository = UserProfileRepository(
      firestore,
      storage,
      facade,
      sessionWith(),
    );
  });

  test('setProfilePhoto updates exactly thumbnail and profile_photo', () async {
    final userDoc = {
      'first_name': 'Jane',
      'last_name': 'Doe',
      'email': 'jane@example.com',
      'reports': 0,
      'is_verified': true,
      'is_admin': false,
    };
    await firestore.collection('users').doc(testUser.id).set(userDoc);

    await repository.setProfilePhoto(
      profilePhoto: 'gs://bucket/users/user-1/profile_photo/image.png',
      thumbnail:
          'gs://bucket/users/user-1/profile_photo/thumbs/image_200x200.png',
    );

    expect(
        (await firestore.collection('users').doc(testUser.id).get()).data(), {
      ...userDoc,
      'thumbnail':
          'gs://bucket/users/user-1/profile_photo/thumbs/image_200x200.png',
      'profile_photo': 'gs://bucket/users/user-1/profile_photo/image.png',
    });
  });

  test('updateLastActive sets only last_active, to a timestamp', () async {
    final userDoc = {
      'first_name': 'Jane',
      'last_name': 'Doe',
      'email': 'jane@example.com',
      'reports': 0,
      'is_verified': true,
      'is_admin': false,
    };
    await firestore.collection('users').doc('u1').set(userDoc);

    await repository.updateLastActive('u1');

    final data = (await firestore.collection('users').doc('u1').get()).data()!;
    expect(data['last_active'], isA<Timestamp>());
    expect(data..remove('last_active'), userDoc);
  });

  test('updateLastActive fails for a missing user document', () async {
    await expectLater(repository.updateLastActive('nobody'), throwsA(anything));
  });

  test('uploadProfilePhoto uploads to the pre-refactor path', () {
    final handle = MockUploadHandle();
    when(() => storage.startUpload(any(), any())).thenReturn(handle);

    expect(repository.uploadProfilePhoto(image), same(handle));
    verify(() =>
            storage.startUpload('/users/user-1/profile_photo/image.png', image))
        .called(1);
  });

  test('uploadProfilePhoto failures are thrown as UserProfileException', () {
    when(() => storage.startUpload(any(), any())).thenThrow(Exception('x'));

    expect(
      () => repository.uploadProfilePhoto(image),
      throwsA(isA<UserProfileException>().having(
          (e) => e.code, 'code', UserProfileExceptionCode.unableToUploadImage)),
    );
  });

  test('refreshCurrentUser delegates to the facade', () async {
    when(() => facade.getSignedInUser()).thenAnswer((_) async => testUser);

    expect(await repository.refreshCurrentUser(), testUser);
    verify(() => facade.getSignedInUser()).called(1);
  });
}
