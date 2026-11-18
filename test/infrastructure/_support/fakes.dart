// Mocks of Firestore's @sealed Query/DocumentReference are needed to inject
// failures (B4); fake_cloud_firestore cannot throw on demand.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/authentication/interfaces.dart';
import 'package:wpa_app/domain/common/media_upload.dart';
import 'package:wpa_app/infrastructure/session/app_session.dart';
import 'package:wpa_app/services/firebase_storage_service.dart';

class MockFirebaseStorageService extends Mock
    implements FirebaseStorageService {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockAuthenticationFacade extends Mock implements IAuthenticationFacade {}

class MockUploadHandle extends Mock implements UploadHandle {}

class FakeImageData extends Fake implements ImageData {}

/// Download URL the storage mock resolves for a `gs://` [location].
String downloadUrlFor(String location) => 'https://download/$location';

/// Storage mock that resolves every `gs://` location to [downloadUrlFor].
MockFirebaseStorageService createStorageMock() {
  final storage = MockFirebaseStorageService();
  when(() => storage.getDownloadUrl(any()))
      .thenAnswer((i) async => downloadUrlFor(i.positionalArguments[0]));
  when(() => storage.getNullableDownloadUrl(any())).thenAnswer((i) async {
    final String? location = i.positionalArguments[0];
    return location == null ? null : downloadUrlFor(location);
  });
  when(() => storage.tryGetDownloadUrl(any())).thenAnswer((i) async {
    final String? location = i.positionalArguments[0];
    return location == null ? null : downloadUrlFor(location);
  });
  return storage;
}

const testUser = LocalUser(
  id: 'user-1',
  firstName: 'Jane',
  lastName: 'Doe',
  email: 'jane@example.com',
  reports: 0,
  thumbnailUrl: 'https://download/gs://bucket/users/user-1/thumb.jpg',
  thumbnail: 'gs://bucket/users/user-1/thumb.jpg',
  isAdmin: false,
  isVerified: true,
);

AppSession sessionWith([LocalUser? user = testUser]) =>
    AppSession()..update(user);

/// A fixed local date that survives a Timestamp round-trip.
DateTime day(int d, [int hour = 12]) => DateTime(2024, 3, d, hour);

Timestamp ts(int d, [int hour = 12]) => Timestamp.fromDate(day(d, hour));

/// Returns [data] without [keys] (used to compare maps that contain
/// non-deterministic timestamps, which are asserted separately).
Map<String, dynamic> without(Map<String, dynamic>? data, List<String> keys) =>
    Map.of(data!)..removeWhere((k, _) => keys.contains(k));

FirebaseException firestoreError(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);
