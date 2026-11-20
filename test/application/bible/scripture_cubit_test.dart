import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/bible/scripture_cubit.dart';
import 'package:wpa_app/application/common/app_events.dart';
import 'package:wpa_app/application/common/load_status.dart';
import 'package:wpa_app/domain/bible/entities.dart';

import '../../helpers/fakes.dart';

const _seriesId = 'series-1';
const _seriesBible = 'bible-$_seriesId';

final _john = buildPassage(
  id: 'JHN.3.16-JHN.3.17',
  reference: 'John 3:16-17',
  verses: {
    'JHN.3.16': 'For God so loved the world',
    'JHN.3.17': 'For God did not send his Son',
  },
);
final _psalm = buildPassage(
  id: 'PSA.23.1-PSA.23.2',
  reference: 'Psalms 23:1-2',
  verses: {
    'PSA.23.1': 'The Lord is my shepherd',
    'PSA.23.2': 'He makes me lie down',
  },
);

const _kjv = BibleVersion(
  id: _seriesBible,
  name: 'King James Version',
  abbreviation: 'KJV',
  languageId: 'eng',
  languageName: 'English',
);
const _web = BibleVersion(
  id: 'web',
  name: 'World English Bible',
  abbreviation: 'WEB',
  languageId: 'eng',
  languageName: 'English',
);
const _rvr = BibleVersion(
  id: 'rvr',
  name: 'Reina Valera',
  abbreviation: 'RVR',
  languageId: 'spa',
  languageName: 'Español',
);

void main() {
  late FakeBibleSeriesRepository series;
  late FakeBiblePassageRepository passages;
  late FakeBibleVersionRepository versions;
  late FakeBibleReaderRepository reader;
  late AppEventBus events;

  setUp(() {
    series = FakeBibleSeriesRepository()
      ..seriesById[_seriesId] = buildSeries(id: _seriesId, days: []);
    passages = FakeBiblePassageRepository()
      ..passages[_john.id] = _john
      ..passages[_psalm.id] = _psalm;
    versions = FakeBibleVersionRepository()..versions = [_rvr, _web, _kjv];
    reader = FakeBibleReaderRepository();
    events = AppEventBus();
  });

  tearDown(() => events.dispose());

  ScriptureCubit build() => ScriptureCubit(
        bibleSeriesId: _seriesId,
        contentId: 'c1',
        bibleSeriesRepository: series,
        biblePassageRepository: passages,
        bibleVersionRepository: versions,
        bibleReaderRepository: reader,
        events: events,
      );

  Future<ScriptureCubit> loaded() async {
    final cubit = build();
    await cubit.load([_john.id, _psalm.id]);
    await pumpEventQueue();
    return cubit;
  }

  /// A saved verse of this series day (content `c1`) unless [contentId]
  /// says otherwise.
  SavedVerse saved(
    String id,
    List<String> verseIds, {
    String? note,
    String contentId = 'c1',
    BibleVersion version = _kjv,
  }) =>
      SavedVerse(
        id: id,
        verseIds: verseIds,
        reference: '',
        bibleId: version.id,
        versionAbbreviation: version.abbreviation,
        seriesId: _seriesId,
        contentId: contentId,
        note: note,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  group('load', () {
    test('loads each passage in the series version, versions and saved verses',
        () async {
      reader.savedVerses.add(saved('a1', ['PSA.23.1']));
      final cubit = await loaded();
      final s = cubit.state;

      expect(s.bibleId, _seriesBible);
      expect(s.preferredBibleId, isNull);
      expect(s.passages[_john.id]?.passage?.id, _john.id);
      expect(s.passages[_psalm.id]?.passage?.id, _psalm.id);
      expect(passages.bibleIds, [_seriesBible, _seriesBible]);
      expect(series.callCount('getBibleSeriesDetails'), 1);
      expect(s.versionsStatus, LoadStatus.success);
      expect(s.versions.map((v) => v.abbreviation), ['KJV', 'WEB', 'RVR']);
      expect(s.abbreviationOf(s.bibleId), 'KJV');
      expect(s.savedVerseIds, {'PSA.23.1'});
      expect(reader.contentQueries, ['c1']); // one query for the day
      await cubit.close();
    });

    test('shows only the saved verses of this series day', () async {
      reader.savedVerses.addAll([
        saved('here', ['JHN.3.16']),
        saved('other-day', ['JHN.3.17', 'PSA.23.1'], contentId: 'c2'),
      ]);
      final cubit = await loaded();

      expect(cubit.state.savedVerses.map((v) => v.id), ['here']);
      expect(cubit.state.savedVerseIds, {'JHN.3.16'});

      // The same verse saved on another day is not "saved" here.
      cubit.toggleVerse('PSA.23.1');
      expect(cubit.state.isSelectionSaved, isFalse);
      await cubit.close();
    });

    test('saved verses that fail to load are retried with a passage', () async {
      reader
        ..savedVerses.add(saved('here', ['JHN.3.16']))
        ..failOn('getSavedVersesForContent');
      passages.passages.remove(_psalm.id);
      final cubit = await loaded();
      expect(cubit.state.savedVerses, isEmpty);
      expect(cubit.state.passages[_john.id]?.passage, isNotNull);

      reader.succeedOn('getSavedVersesForContent');
      passages.passages[_psalm.id] = _psalm;
      await cubit.retryPassage(_psalm.id);
      await pumpEventQueue();
      expect(cubit.state.savedVerseIds, {'JHN.3.16'});

      // Once loaded, reloading passages (version switch) doesn't query again.
      final queries = reader.callCount('getSavedVersesForContent');
      cubit.toggleVerse('JHN.3.16');
      await cubit.selectBible('web');
      await pumpEventQueue();
      expect(reader.callCount('getSavedVersesForContent'), queries);
      await cubit.close();
    });

    test('does nothing without passages or when already loaded', () async {
      final cubit = build();
      await cubit.load([]);
      expect(passages.calls, isEmpty);

      await cubit.load([_john.id]);
      await cubit.load([_psalm.id]);
      expect(cubit.state.passageIds, [_john.id]);
      await cubit.close();
    });

    test('reads in the version the user chose, even without the series',
        () async {
      reader.preferredBibleId = 'web';
      series.seriesById.clear();
      final cubit = await loaded();

      expect(cubit.state.bibleId, 'web');
      expect(cubit.state.passages[_john.id]?.passage?.bibleId, 'web');
      expect(passages.bibleIds, ['web', 'web']);
      await cubit.close();
    });

    test('without the series, passages fail and a retry reloads it', () async {
      series.seriesById.clear();
      final cubit = await loaded();

      expect(cubit.state.passages[_john.id], const PassageLoad.failed());
      expect(cubit.state.passages[_psalm.id], const PassageLoad.failed());
      expect(passages.calls, isEmpty);

      series.seriesById[_seriesId] = buildSeries(id: _seriesId, days: []);
      final retry = cubit.retryPassage(_john.id);
      expect(cubit.state.passages[_john.id], const PassageLoad.loading());
      await retry;
      expect(cubit.state.passages[_john.id]?.passage?.id, _john.id);
      await cubit.close();
    });

    test('a failed passage can be retried', () async {
      passages.passages.remove(_psalm.id);
      final cubit = await loaded();
      expect(cubit.state.passages[_psalm.id], const PassageLoad.failed());

      passages.passages[_psalm.id] = _psalm;
      await cubit.retryPassage(_psalm.id);
      expect(cubit.state.passages[_psalm.id]?.passage?.id, _psalm.id);
      await cubit.close();
    });

    test('a version list failure can be retried', () async {
      versions.failOn('getBibles');
      final cubit = await loaded();
      expect(cubit.state.versionsStatus, LoadStatus.failure);

      versions.succeedOn('getBibles');
      await cubit.retryVersions();
      expect(cubit.state.versionsStatus, LoadStatus.success);
      await cubit.close();
    });
  });

  group('version', () {
    test('selecting a version saves it and reloads the passages in it',
        () async {
      final cubit = await loaded();
      cubit.toggleVerse('JHN.3.16');
      passages.bibleIds.clear();

      await cubit.selectBible('web');
      expect(cubit.state.preferredBibleId, 'web');
      expect(cubit.state.selectedVerseIds, isEmpty);
      await pumpEventQueue();
      expect(reader.preferredBibleId, 'web');
      expect(passages.bibleIds, ['web', 'web']);
      expect(cubit.state.passages[_john.id]?.passage?.bibleId, 'web');

      await cubit.selectBible(null);
      await pumpEventQueue();
      expect(reader.preferredBibleId, isNull);
      expect(cubit.state.bibleId, _seriesBible);
      expect(cubit.state.passages[_john.id]?.passage?.bibleId, _seriesBible);
      await cubit.close();
    });

    test('only saved verses of the version being read are shown', () async {
      reader.savedVerses.addAll([
        saved('kjv', ['JHN.3.16'], note: 'KJV note'),
        saved('web', ['PSA.23.1'], note: 'WEB note', version: _web),
      ]);
      final cubit = await loaded();

      expect(cubit.state.savedVerses, hasLength(2));
      expect(cubit.state.versionSavedVerses.map((v) => v.id), ['kjv']);
      expect(cubit.state.savedVerseIds, {'JHN.3.16'});
      expect(cubit.state.notedVerseIds, {'JHN.3.16'});
      expect(cubit.state.notesFor('PSA.23.1'), isEmpty);

      await cubit.selectBible('web');
      expect(cubit.state.savedVerseIds, {'PSA.23.1'});
      expect(cubit.state.notedVerseIds, {'PSA.23.1'});
      expect(cubit.state.notesFor('JHN.3.16'), isEmpty);

      await cubit.selectBible(null);
      expect(cubit.state.savedVerseIds, {'JHN.3.16'});
      await cubit.close();
    });

    test('save, unsave and notes ignore saved verses of other versions',
        () async {
      reader.savedVerses.add(saved('kjv', ['JHN.3.16'], note: 'KJV note'));
      final cubit = await loaded();
      await cubit.selectBible('web');
      await pumpEventQueue();

      cubit.toggleVerse('JHN.3.16');
      expect(cubit.state.isSelectionSaved, isFalse);
      expect(cubit.state.selectionSavedVerses, isEmpty);
      expect(cubit.state.noteTarget, isNull);

      await cubit.toggleSaveSelection();
      expect(reader.added.single.bibleId, 'web');
      expect(reader.savedVerses.map((v) => v.id), contains('kjv'));
      expect(cubit.state.savedVerseIds, {'JHN.3.16'});
      expect(cubit.state.notedVerseIds, isEmpty);

      // Unsaving in WEB leaves the KJV saved verse.
      cubit.toggleVerse('JHN.3.16');
      await cubit.toggleSaveSelection();
      expect(reader.savedVerses.map((v) => v.id), ['kjv']);
      expect(cubit.state.savedVerseIds, isEmpty);
      await cubit.close();
    });

    test('a failed save still switches and shows an error', () async {
      reader.failOn('setPreferredBibleId');
      final cubit = await loaded();
      await cubit.selectBible('web');

      expect(cubit.state.bibleId, 'web');
      expect(cubit.state.message, 'Unable to save your Bible version');
      expect(cubit.state.messageIsError, isTrue);
      await cubit.close();
    });
  });

  group('selection', () {
    test('is in reading order with a grouped reference and text', () async {
      final cubit = await loaded();
      cubit
        ..toggleVerse('PSA.23.1')
        ..toggleVerse('JHN.3.17')
        ..toggleVerse('JHN.3.16');

      final s = cubit.state;
      expect(s.selection, ['JHN.3.16', 'JHN.3.17', 'PSA.23.1']);
      expect(s.selectionReference, 'John 3:16-17; Psalms 23:1');
      expect(
        s.selectionText,
        '16 For God so loved the world 17 For God did not send his Son '
        '1 The Lord is my shepherd',
      );

      cubit.toggleVerse('JHN.3.17');
      expect(cubit.state.selectionReference, 'John 3:16; Psalms 23:1');
      cubit.clearSelection();
      expect(cubit.state.selection, isEmpty);
      await cubit.close();
    });
  });

  group('save', () {
    test('saves the selection without a note, then removes it', () async {
      final cubit = await loaded();
      cubit
        ..toggleVerse('JHN.3.16')
        ..toggleVerse('JHN.3.17');
      expect(cubit.state.isSelectionSaved, isFalse);

      await cubit.toggleSaveSelection();
      final added = reader.added.single;
      expect(added.note, isNull);
      expect(added.verseIds, ['JHN.3.16', 'JHN.3.17']);
      expect(added.reference, 'John 3:16-17');
      expect(added.bibleId, _seriesBible);
      expect(added.versionAbbreviation, 'KJV');
      expect(added.seriesId, _seriesId);
      expect(added.contentId, 'c1');
      expect(cubit.state.selection, isEmpty);
      expect(cubit.state.savedVerseIds, {'JHN.3.16', 'JHN.3.17'});
      expect(cubit.state.notedVerseIds, isEmpty);
      expect(cubit.state.message, 'Saved John 3:16-17');

      cubit.toggleVerse('JHN.3.17');
      expect(cubit.state.isSelectionSaved, isTrue);
      expect(cubit.state.selectionSavedVerses, hasLength(1));
      await cubit.toggleSaveSelection();
      expect(reader.savedVerses, isEmpty);
      expect(cubit.state.savedVerseIds, isEmpty);
      expect(cubit.state.selection, isEmpty);
      expect(cubit.state.message, 'Removed from saved');
      await cubit.close();
    });

    test('a failure keeps the selection and shows an error', () async {
      reader.failOn('addSavedVerse');
      final cubit = await loaded();
      cubit.toggleVerse('JHN.3.16');
      await cubit.toggleSaveSelection();

      expect(cubit.state.selection, ['JHN.3.16']);
      expect(cubit.state.message, 'Unable to save verses');
      expect(cubit.state.messageIsError, isTrue);
      await cubit.close();
    });
  });

  group('series title and day', () {
    ScriptureCubit buildFor(String contentId) => ScriptureCubit(
          bibleSeriesId: _seriesId,
          contentId: contentId,
          bibleSeriesRepository: series,
          biblePassageRepository: passages,
          bibleVersionRepository: versions,
          bibleReaderRepository: reader,
          events: events,
        );

    test('are stored with a save, reusing the loaded series', () async {
      series.seriesById[_seriesId] = buildSeries(
        id: _seriesId,
        days: [
          DateTime(2026, 3, 1),
          DateTime(2026, 3, 2),
          DateTime(2026, 3, 3)
        ],
      );
      final cubit = buildFor('day1-read'); // the 2nd day
      await cubit.load([_john.id]);
      await pumpEventQueue();

      cubit.toggleVerse('JHN.3.16');
      await cubit.toggleSaveSelection();
      cubit.toggleVerse('JHN.3.17');
      await cubit.saveNote('Note');

      for (final added in reader.added) {
        expect(added.seriesTitle, 'Series $_seriesId');
        expect(added.day, 2);
        expect(added.contentId, 'day1-read');
      }
      expect(reader.added, hasLength(2));
      expect(cubit.state.savedVerses.first.day, 2);
      expect(series.callCount('getBibleSeriesDetails'), 1);
      await cubit.close();
    });

    test('are left out when the series is unavailable', () async {
      reader.preferredBibleId = 'web'; // passages load without the series
      series.seriesById.clear();
      final cubit = buildFor('day1-read');
      await cubit.load([_john.id]);
      await pumpEventQueue();

      cubit.toggleVerse('JHN.3.16');
      await cubit.toggleSaveSelection();

      expect(reader.added.single.seriesTitle, '');
      expect(reader.added.single.day, isNull);
      expect(cubit.state.message, 'Saved John 3:16');
      await cubit.close();
    });
  });

  group('notes', () {
    test('a note on unsaved verses saves them with the note', () async {
      final cubit = await loaded();
      cubit.toggleVerse('PSA.23.2');
      expect(cubit.state.noteTarget, isNull);

      expect(await cubit.saveNote('   '), isFalse);
      expect(await cubit.saveNote(' Rest '), isTrue);

      final added = reader.added.single;
      expect(added.note, 'Rest');
      expect(added.verseIds, ['PSA.23.2']);
      expect(cubit.state.selection, isEmpty);
      expect(cubit.state.savedVerseIds, {'PSA.23.2'});
      expect(cubit.state.notesFor('PSA.23.2').single.note, 'Rest');
      expect(cubit.state.message, 'Note saved');
      await cubit.close();
    });

    test('a note on saved verses goes on that saved verse', () async {
      reader.savedVerses.add(saved('s1', ['JHN.3.16', 'JHN.3.17']));
      final cubit = await loaded();
      cubit.toggleVerse('JHN.3.17'); // inside the saved verses
      expect(cubit.state.noteTarget?.id, 's1');

      expect(await cubit.saveNote('Sent to save'), isTrue);

      expect(reader.added, isEmpty); // no new record
      expect(reader.savedVerses.single.note, 'Sent to save');
      expect(cubit.state.savedVerses.single.note, 'Sent to save');
      expect(cubit.state.notedVerseIds, {'JHN.3.16', 'JHN.3.17'});
      await cubit.close();
    });

    test('the smallest saved verse containing the selection is used', () async {
      reader.savedVerses.addAll([
        saved('wide', ['JHN.3.16', 'JHN.3.17']),
        saved('narrow', ['JHN.3.17']),
      ]);
      final cubit = await loaded();
      cubit.toggleVerse('JHN.3.17');
      expect(cubit.state.noteTarget?.id, 'narrow');

      cubit
        ..clearSelection()
        ..toggleVerse('JHN.3.17')
        ..toggleVerse('PSA.23.1'); // not inside any saved verse
      expect(cubit.state.noteTarget, isNull);
      await cubit.close();
    });

    test('editing and deleting a note keeps the verses saved', () async {
      reader.savedVerses.add(saved('s1', ['PSA.23.1'], note: 'Shepherd'));
      final cubit = await loaded();

      expect(await cubit.setNote('s1', 'Green pastures'), isTrue);
      expect(reader.savedVerses.single.note, 'Green pastures');
      expect(cubit.state.notesFor('PSA.23.1').single.note, 'Green pastures');
      expect(cubit.state.message, 'Note saved');

      expect(await cubit.setNote('s1', null), isTrue);
      expect(reader.savedVerses.single.note, isNull);
      expect(cubit.state.notedVerseIds, isEmpty);
      expect(cubit.state.savedVerseIds, {'PSA.23.1'});
      expect(cubit.state.message, 'Note deleted');
      await cubit.close();
    });

    test('unsaving removes the note with the saved verse', () async {
      reader.savedVerses.add(saved('s1', ['PSA.23.1'], note: 'Shepherd'));
      final cubit = await loaded();
      cubit.toggleVerse('PSA.23.1');
      expect(cubit.state.selectionSavedVerses.single.hasNote, isTrue);

      await cubit.toggleSaveSelection();
      expect(reader.savedVerses, isEmpty);
      expect(cubit.state.notedVerseIds, isEmpty);
      await cubit.close();
    });

    test('without a selection no note is written', () async {
      final cubit = await loaded();
      expect(await cubit.saveNote('Hello'), isFalse);
      expect(reader.calls, isNot(contains('addSavedVerse')));
      await cubit.close();
    });
  });

  group('compare', () {
    test('defaults to another version in the same language', () async {
      final cubit = await loaded();
      expect(cubit.state.defaultCompareBibleId, 'web');
      await cubit.close();
    });

    test('loads the selected verses of each passage in another version',
        () async {
      passages.passagesByBible['web/JHN.3.16-JHN.3.17'] = buildPassage(
        id: 'JHN.3.16-JHN.3.17',
        reference: 'John 3:16-17',
        bibleId: 'web',
        verses: {'JHN.3.16': 'For God loved', 'JHN.3.17': 'God sent'},
      );
      passages.passagesByBible['web/PSA.23.2'] = buildPassage(
        id: 'PSA.23.2',
        reference: 'Psalms 23:2',
        bibleId: 'web',
        verses: {},
      );
      final cubit = await loaded();
      cubit
        ..toggleVerse('JHN.3.16')
        ..toggleVerse('JHN.3.17')
        ..toggleVerse('PSA.23.2');
      passages.passageIds.clear();

      final done = cubit.compare('web');
      expect(
        cubit.state.comparison,
        const VerseComparison(bibleId: 'web', status: LoadStatus.loading),
      );
      await done;

      expect(passages.passageIds, ['JHN.3.16-JHN.3.17', 'PSA.23.2']);
      expect(
        cubit.state.comparison,
        const VerseComparison(
          bibleId: 'web',
          status: LoadStatus.success,
          verses: [
            VerseText(verseId: 'JHN.3.16', text: 'For God loved'),
            VerseText(verseId: 'JHN.3.17', text: 'God sent'),
            VerseText(verseId: 'PSA.23.2', text: ''),
          ],
        ),
      );

      cubit.closeComparison();
      expect(cubit.state.comparison, isNull);
      await cubit.close();
    });

    test('a failure can be retried', () async {
      final cubit = await loaded();
      cubit.toggleVerse('JHN.3.16');
      passages.failOn('getPassage');
      await cubit.compare('web');
      expect(cubit.state.comparison?.status, LoadStatus.failure);
      await cubit.close();
    });

    test('a closed comparison is not reopened by a late result', () async {
      final cubit = await loaded();
      cubit.toggleVerse('JHN.3.16');
      final done = cubit.compare('web');
      cubit.closeComparison();
      await done;
      expect(cubit.state.comparison, isNull);
      await cubit.close();
    });
  });

  group('events', () {
    test('publishes saves, note changes and removals', () async {
      final changed = <SavedVerseChanged>[];
      final deleted = <SavedVerseDeleted>[];
      events.on<SavedVerseChanged>().listen(changed.add);
      events.on<SavedVerseDeleted>().listen(deleted.add);
      final cubit = await loaded();

      cubit.toggleVerse('JHN.3.16');
      await cubit.saveNote('Love');
      final v = changed.single.savedVerse;
      expect(v.note, 'Love');

      await cubit.setNote(v.id, 'Grace');
      expect(changed.last.savedVerse.note, 'Grace');
      expect(changed.last.savedVerse.id, v.id);

      cubit.toggleVerse('JHN.3.16');
      await cubit.toggleSaveSelection();
      expect(deleted.single.id, v.id);
      await cubit.close();
    });

    test('applies changes made elsewhere to this series day only', () async {
      final v = saved('n1', ['PSA.23.1'], note: 'Shepherd');
      reader.savedVerses.add(v);
      final cubit = await loaded();

      events.emit(SavedVerseChanged(v.withNote('Edited')));
      expect(cubit.state.notesFor('PSA.23.1').single.note, 'Edited');

      events.emit(SavedVerseChanged(saved('s1', ['JHN.3.17'])));
      expect(cubit.state.savedVerseIds, {'PSA.23.1', 'JHN.3.17'});

      events.emit(SavedVerseChanged(
          saved('other', ['JHN.3.16'], contentId: 'another-day')));
      expect(cubit.state.savedVerses.map((x) => x.id),
          unorderedEquals(['n1', 's1']));

      events.emit(const SavedVerseDeleted('n1'));
      expect(cubit.state.notedVerseIds, isEmpty);
      await cubit.close();
    });
  });
}
