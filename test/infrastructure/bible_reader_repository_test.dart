import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/bible/entities.dart';
import 'package:wpa_app/infrastructure/bible/bible_reader_repository.dart';

import '_support/fakes.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late BibleReaderRepository repository;
  final now = DateTime(2026, 3, 2, 10);

  DocumentReference<Map<String, dynamic>> user() =>
      firestore.collection('users').doc(testUser.id);

  CollectionReference<Map<String, dynamic>> savedVerses() =>
      user().collection('saved_verses');

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repository =
        BibleReaderRepository(firestore, sessionWith(), clock: () => now);
    await user().set({'first_name': 'Jane'});
  });

  const withNote = NewSavedVerse(
    seriesTitle: 'Hope in Hard Times',
    day: 3,
    verseIds: ['JHN.3.16', 'JHN.3.17'],
    reference: 'John 3:16-17',
    bibleId: 'kjv',
    versionAbbreviation: 'KJV',
    note: 'Love',
    seriesId: 's1',
    contentId: 'c1',
  );

  group('preferred version', () {
    test('reads, sets and clears users/{uid}.preferred_bible_id', () async {
      expect(await repository.getPreferredBibleId(), isNull);

      await repository.setPreferredBibleId('web');
      expect((await user().get()).data(),
          {'first_name': 'Jane', 'preferred_bible_id': 'web'});
      expect(await repository.getPreferredBibleId(), 'web');

      await repository.setPreferredBibleId(null);
      expect((await user().get()).data(), {'first_name': 'Jane'});
      expect(await repository.getPreferredBibleId(), isNull);
    });

    test('reads a stored value', () async {
      await user().update({'preferred_bible_id': 'rvr'});
      expect(await repository.getPreferredBibleId(), 'rvr');
    });
  });

  group('saved verses', () {
    test('adds a saved verse with exactly these fields', () async {
      final added = await repository.addSavedVerse(withNote);

      expect(added.id, isNotEmpty);
      expect(added.note, 'Love');
      expect(added.createdAt, now);
      final data = (await savedVerses().doc(added.id).get()).data()!;
      expect(data['created_at'], isA<Timestamp>());
      expect(data['updated_at'], isA<Timestamp>());
      expect(
          data
            ..remove('created_at')
            ..remove('updated_at'),
          {
            'verse_ids': ['JHN.3.16', 'JHN.3.17'],
            'reference': 'John 3:16-17',
            'bible_id': 'kjv',
            'version_abbreviation': 'KJV',
            'note': 'Love',
            'series_id': 's1',
            'content_id': 'c1',
            'series_title': 'Hope in Hard Times',
            'day': 3,
          });
      expect(added.seriesTitle, 'Hope in Hard Times');
      expect(added.day, 3);
    });

    test('without a note, note is written as null', () async {
      final added = await repository.addSavedVerse(const NewSavedVerse(
        verseIds: ['PSA.23.1'],
        reference: 'Psalms 23:1',
        bibleId: 'kjv',
        versionAbbreviation: 'KJV',
        seriesId: 's1',
        contentId: 'c2',
      ));
      final data = (await savedVerses().doc(added.id).get()).data()!;
      expect(data.containsKey('note'), isTrue);
      expect(data['note'], isNull);
      expect(added.note, isNull);
    });

    test('finds the saved verses of one series day', () async {
      final a = await repository.addSavedVerse(withNote); // content c1
      await savedVerses().add({
        'verse_ids': ['GEN.1.1'],
        'note': null,
        'series_id': 's1',
        'content_id': 'c1',
        'created_at': Timestamp.fromDate(DateTime(2026)),
      });
      await savedVerses().add({
        'verse_ids': ['JHN.3.16'], // same verse, another day
        'note': null,
        'series_id': 's1',
        'content_id': 'c9',
        'created_at': Timestamp.fromDate(DateTime(2026)),
      });
      await savedVerses().add({
        'verse_ids': <String>[], // malformed: skipped
        'series_id': 's1',
        'content_id': 'c1',
      });
      await savedVerses().add({
        'verse_ids': ['PSA.1.1'], // malformed: no series_id
        'content_id': 'c1',
      });

      final found = await repository.getSavedVersesForContent('c1');

      expect(found.map((x) => x.verseIds), [
        ['GEN.1.1'],
        ['JHN.3.16', 'JHN.3.17'],
      ]);
      expect(found.first.note, isNull);
      expect(found.last.id, a.id);
      expect(found.last.note, 'Love');
      expect(found.last.seriesId, 's1');
      expect(found.last.contentId, 'c1');
      expect(found.last.seriesTitle, 'Hope in Hard Times');
      expect(found.last.day, 3);
      expect(found.first.seriesTitle, ''); // not stored
      expect(found.first.day, isNull);
      expect(await repository.getSavedVersesForContent('none'), isEmpty);
    });

    test('a blank note reads as no note', () async {
      await savedVerses().add({
        'verse_ids': ['JHN.3.16'],
        'note': '  ',
        'series_id': 's1',
        'content_id': 'c1',
        'created_at': Timestamp.fromDate(DateTime(2026)),
      });
      final found = await repository.getSavedVersesForContent('c1');
      expect(found.single.note, isNull);
    });

    test('pages all saved verses newest first', () async {
      for (var day = 1; day <= 3; day++) {
        await savedVerses().add({
          'verse_ids': ['PSA.23.$day'],
          'note': null,
          'series_id': 's1',
          'content_id': 'c$day',
          'created_at': Timestamp.fromDate(DateTime(2026, 3, day)),
        });
      }

      final first = await repository.getSavedVersesPage(limit: 2);
      expect(
          first.items.map((v) => v.verseIds.single), ['PSA.23.3', 'PSA.23.2']);
      expect(first.isEnd, isFalse);

      final second = await repository.getSavedVersesPage(
          limit: 2, after: first.nextCursor);
      expect(second.items.map((v) => v.verseIds.single), ['PSA.23.1']);
      expect(second.isEnd, isTrue);
    });

    test('sets, changes and clears the note of the same document', () async {
      final added = await repository.addSavedVerse(const NewSavedVerse(
        verseIds: ['PSA.23.1'],
        reference: 'Psalms 23:1',
        bibleId: 'kjv',
        versionAbbreviation: 'KJV',
        seriesId: 's1',
        contentId: 'c2',
      ));
      Future<Object?> note() async =>
          (await savedVerses().doc(added.id).get()).data()!['note'];

      await repository.setNote(savedVerseId: added.id, note: 'Shepherd');
      expect(await note(), 'Shepherd');
      await repository.setNote(savedVerseId: added.id, note: 'Leads me');
      expect(await note(), 'Leads me');
      await repository.setNote(savedVerseId: added.id, note: null);
      expect(await note(), isNull);
      expect((await savedVerses().get()).docs, hasLength(1));
    });

    test('deletes a saved verse', () async {
      final added = await repository.addSavedVerse(withNote);
      await repository.deleteSavedVerse(added.id);
      expect((await savedVerses().doc(added.id).get()).exists, isFalse);
    });
  });
}
