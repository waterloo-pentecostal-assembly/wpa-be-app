import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/common/search.dart';
import 'package:wpa_app/infrastructure/challenge_groups/user_directory_repository.dart';

import '_support/fakes.dart';

/// A `users/{uid}` document with the search tokens the backend adds.
Map<String, dynamic> userDoc(
  String first,
  String last, {
  bool verified = true,
  String? thumbnail,
}) =>
    {
      'first_name': first,
      'last_name': last,
      'email': '$first@example.com',
      'reports': 0,
      'is_verified': verified,
      'is_admin': false,
      if (thumbnail != null) 'thumbnail': thumbnail,
      // As the backend computes them (domain/common/search.dart).
      kSearchTokensField: searchTokens('$first $last'),
    };

void main() {
  late FakeFirebaseFirestore firestore;
  late UserDirectoryRepository repository;

  CollectionReference<Map<String, dynamic>> users() =>
      firestore.collection('users');

  Future<void> add(String id, String first, String last,
          {bool verified = true, String? thumbnail}) =>
      users()
          .doc(id)
          .set(userDoc(first, last, verified: verified, thumbnail: thumbnail));

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repository =
        UserDirectoryRepository(firestore, createStorageMock(), sessionWith());
    await add('u2', 'Mary', 'Smith');
    await add('u3', 'Mark', 'Jones');
    await add('u4', 'Sam', 'Marley');
    await add('u5', 'Peter', 'Parker');
    await add('u6', 'Marvin', 'Pending', verified: false);
    await add(testUser.id, 'Martha', 'Me');
  });

  test('matches first names, full names and last names, any case', () async {
    final results = await repository.search('MAR');
    expect(results.map((u) => u.fullName),
        ['Mark Jones', 'Mary Smith', 'Sam Marley']);
  });

  test('matches the start of a full name', () async {
    // One-letter words are ignored until a second letter is typed.
    expect((await repository.search('mary s')).map((u) => u.id), ['u2']);
    expect((await repository.search('mary sm')).map((u) => u.id), ['u2']);
    expect(await repository.search('mary jo'), isEmpty);
  });

  test('words match in any order, including middle names', () async {
    await add('u9', 'Mary Ann', 'Smith-Jones');
    expect((await repository.search('jones mary')).map((u) => u.id), ['u9']);
    expect((await repository.search('ann')).map((u) => u.id), ['u9']);
  });

  test('users without tokens are not found', () async {
    await users().doc('u10').set({
          ...userDoc('Nora', 'Old'),
        }..remove(kSearchTokensField));
    expect(await repository.search('nora'), isEmpty);
  });

  test('leaves out unverified users and the signed-in user', () async {
    expect(await repository.search('marvin'), isEmpty);
    expect(await repository.search('martha'), isEmpty);
  });

  test('trims stored names and resolves avatar URLs', () async {
    await add('u8', 'Zed ', 'Z', thumbnail: 'gs://z.jpg');
    final user = (await repository.search('zed')).single;
    expect(user.firstName, 'Zed');
    expect(user.thumbnailUrl, downloadUrlFor('gs://z.jpg'));
  });

  test('short queries return nothing', () async {
    expect(await repository.search('m'), isEmpty);
    expect(await repository.search('  '), isEmpty);
  });

  test('applies the limit after merging', () async {
    final results = await repository.search('mar', limit: 2);
    expect(results, hasLength(2));
  });
}
