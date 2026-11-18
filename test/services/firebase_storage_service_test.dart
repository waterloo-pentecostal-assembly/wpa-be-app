import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/services/firebase_storage_service.dart';

class _MockStorage extends Mock implements FirebaseStorage {}

class _MockReference extends Mock implements Reference {}

void main() {
  late _MockStorage storage;
  late _MockReference ref;
  late FirebaseStorageService service;

  setUp(() {
    storage = _MockStorage();
    ref = _MockReference();
    when(() => storage.refFromURL(any())).thenReturn(ref);
    service = FirebaseStorageService(storage);
  });

  test('concurrent lookups of one location share a single request', () async {
    final completer = Completer<String>();
    when(() => ref.getDownloadURL()).thenAnswer((_) => completer.future);

    final lookups = [
      for (var i = 0; i < 5; i++) service.getDownloadUrl('gs://b/a.jpg'),
    ];
    completer.complete('https://a');

    expect(await Future.wait(lookups), everyElement('https://a'));
    expect(await service.getDownloadUrl('gs://b/a.jpg'), 'https://a');
    verify(() => ref.getDownloadURL()).called(1);
  });

  test('a failed lookup is mapped, evicted and retried next time', () async {
    when(() => ref.getDownloadURL()).thenThrow(
        FirebaseException(plugin: 'storage', code: 'object-not-found'));

    await expectLater(
      service.getDownloadUrl('gs://b/gone.jpg'),
      throwsA(isA<StorageException>()
          .having((e) => e.code, 'code', StorageExceptionCode.objectNotFound)),
    );

    when(() => ref.getDownloadURL()).thenAnswer((_) async => 'https://back');
    expect(await service.getDownloadUrl('gs://b/gone.jpg'), 'https://back');
  });

  test('tryGetDownloadUrl returns null instead of throwing', () async {
    when(() => ref.getDownloadURL()).thenThrow(
        FirebaseException(plugin: 'storage', code: 'object-not-found'));

    expect(await service.tryGetDownloadUrl('gs://b/gone.jpg'), isNull);
    expect(await service.tryGetDownloadUrl(null), isNull);
    expect(await service.tryGetDownloadUrl(''), isNull);
    verify(() => storage.refFromURL(any())).called(1);
  });
}
