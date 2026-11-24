import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/bible/bible_notes_cubit.dart';
import 'package:wpa_app/application/common/app_events.dart';
import 'package:wpa_app/application/common/load_status.dart';
import 'package:wpa_app/domain/bible/entities.dart';

import '../../helpers/fakes.dart';

SavedVerse _saved(
  String id, {
  int day = 1,
  String? note,
  List<String> verseIds = const ['JHN.3.16'],
}) =>
    SavedVerse(
      id: id,
      verseIds: verseIds,
      reference: 'John 3:16',
      seriesId: 's1',
      contentId: 'c$day',
      note: note,
      createdAt: DateTime(2026, 3, day),
      updatedAt: DateTime(2026, 3, day),
    );

void main() {
  late FakeBibleReaderRepository reader;
  late FakeBiblePassageRepository passages;
  late FakeBibleSeriesRepository series;
  late FakeBibleVersionRepository versions;
  late AppEventBus events;

  setUp(() {
    reader = FakeBibleReaderRepository()
      ..savedVerses.addAll([
        _saved('a', day: 1, note: 'First'),
        _saved('b', day: 2),
        _saved('c', day: 3, note: 'Third'),
      ]);
    passages = FakeBiblePassageRepository();
    series = FakeBibleSeriesRepository()
      ..seriesById['s1'] = buildSeries(id: 's1', days: []);
    versions = FakeBibleVersionRepository()
      ..versions = const [
        BibleVersion(
            id: 'web', name: 'World English Bible', abbreviation: 'WEB'),
        BibleVersion(
            id: 'kjv', name: 'King James Version', abbreviation: 'KJV'),
      ];
    events = AppEventBus();
  });

  tearDown(() => events.dispose());

  BibleNotesCubit build({int pageSize = 30}) => BibleNotesCubit(
        bibleReaderRepository: reader,
        biblePassageRepository: passages,
        bibleSeriesRepository: series,
        bibleVersionRepository: versions,
        events: events,
        pageSize: pageSize,
      );

  List<String> ids(BibleNotesCubit c) =>
      [for (final v in c.state.visibleItems) v.id];

  test('loads newest first and filters to those with notes', () async {
    final cubit = build();
    await cubit.load();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.isEndOfList, isTrue);
    expect(ids(cubit), ['c', 'b', 'a']);

    cubit.setFilter(BibleNotesFilter.withNotes);
    expect(ids(cubit), ['c', 'a']);
    cubit.setFilter(BibleNotesFilter.all);
    expect(ids(cubit), ['c', 'b', 'a']);
    await cubit.close();
  });

  test('pages until the end', () async {
    final cubit = build(pageSize: 2);
    await cubit.load();
    expect(ids(cubit), ['c', 'b']);
    expect(cubit.state.isEndOfList, isFalse);

    await cubit.loadMore();
    expect(ids(cubit), ['c', 'b', 'a']);
    expect(cubit.state.isEndOfList, isTrue);

    await cubit.loadMore();
    expect(reader.callCount('getSavedVersesPage'), 2);
    await cubit.close();
  });

  test('a load failure can be retried', () async {
    reader.failOn('getSavedVersesPage');
    final cubit = build();
    await cubit.load();
    expect(cubit.state.status, LoadStatus.failure);
    expect(cubit.state.errorMessage, 'Fake failure');

    reader.succeedOn('getSavedVersesPage');
    await cubit.load();
    expect(cubit.state.status, LoadStatus.success);
    await cubit.close();
  });

  group('notes', () {
    test('adding a note updates the same saved verse', () async {
      final published = <SavedVerseChanged>[];
      events.on<SavedVerseChanged>().listen(published.add);
      final cubit = build();
      await cubit.load();

      expect(await cubit.setNote('b', ' New note '), isTrue);

      expect(reader.added, isEmpty); // no new record
      expect(reader.savedVerses, hasLength(3));
      expect(
          reader.savedVerses.firstWhere((v) => v.id == 'b').note, 'New note');
      expect(ids(cubit), ['c', 'b', 'a']); // same row, same place
      expect(cubit.state.items[1].note, 'New note');
      expect(published.single.savedVerse.id, 'b');
      expect(cubit.state.message, 'Note saved');
      await cubit.close();
    });

    test('editing changes the note', () async {
      final cubit = build();
      await cubit.load();
      expect(await cubit.setNote('a', 'Edited'), isTrue);
      expect(reader.savedVerses.firstWhere((v) => v.id == 'a').note, 'Edited');
      expect(cubit.state.items.last.note, 'Edited');
      await cubit.close();
    });

    test('deleting the note keeps the saved verse', () async {
      final cubit = build();
      await cubit.load();

      expect(await cubit.setNote('a', null), isTrue);
      expect(reader.savedVerses.firstWhere((v) => v.id == 'a').note, isNull);
      expect(ids(cubit), ['c', 'b', 'a']);
      expect(cubit.state.message, 'Note deleted');

      cubit.setFilter(BibleNotesFilter.withNotes);
      expect(ids(cubit), ['c']);
      await cubit.close();
    });

    test('a blank note deletes it', () async {
      final cubit = build();
      await cubit.load();
      expect(await cubit.setNote('a', '   '), isTrue);
      expect(reader.savedVerses.firstWhere((v) => v.id == 'a').note, isNull);
      await cubit.close();
    });

    test('a failure keeps the note and shows an error', () async {
      reader.failOn('setNote');
      final cubit = build();
      await cubit.load();

      expect(await cubit.setNote('a', 'Edited'), isFalse);
      expect(cubit.state.items.last.note, 'First');
      expect(cubit.state.message, 'Unable to save note');
      expect(cubit.state.messageIsError, isTrue);

      expect(await cubit.setNote('a', null), isFalse);
      expect(cubit.state.message, 'Unable to delete note');
      await cubit.close();
    });
  });

  group('remove', () {
    test('removes the saved verse with its note and tells the reader',
        () async {
      final published = <SavedVerseDeleted>[];
      events.on<SavedVerseDeleted>().listen(published.add);
      final cubit = build();
      await cubit.load();

      expect(await cubit.remove('a'), isTrue);
      expect(ids(cubit), ['c', 'b']);
      expect(reader.savedVerses.map((v) => v.id), ['b', 'c']);
      expect(published.single.id, 'a');
      expect(cubit.state.message, 'Removed from saved');
      await cubit.close();
    });

    test('a failure keeps it and shows an error', () async {
      reader.failOn('deleteSavedVerse');
      final cubit = build();
      await cubit.load();

      expect(await cubit.remove('a'), isFalse);
      expect(ids(cubit), contains('a'));
      expect(cubit.state.message, 'Unable to remove verse');
      expect(cubit.state.messageIsError, isTrue);
      await cubit.close();
    });
  });

  test('follows changes made in the reader', () async {
    final cubit = build();
    await cubit.load();

    events.emit(SavedVerseChanged(_saved('new', day: 9)));
    expect(ids(cubit).first, 'new');

    events.emit(SavedVerseChanged(_saved('b', day: 2, note: 'From reader')));
    expect(
        cubit.state.items.firstWhere((v) => v.id == 'b').note, 'From reader');
    expect(ids(cubit), hasLength(4));

    events.emit(const SavedVerseDeleted('c'));
    expect(ids(cubit), ['new', 'b', 'a']);
    await cubit.close();
  });

  group('text', () {
    SavedVerse scattered() => _saved(
          'x',
          day: 4,
          verseIds: const ['JHN.3.16', 'JHN.3.18', 'PSA.23.1'],
        );

    setUp(() => reader.preferredBibleId = 'web');

    test('is read in the preferred version, one request per chapter', () async {
      reader.savedVerses.add(scattered());
      passages
        ..passages['JHN.3.16-JHN.3.18'] = buildPassage(
          id: 'JHN.3.16-JHN.3.18',
          reference: 'John 3:16-18',
          verses: {
            'JHN.3.16': 'For God so loved',
            'JHN.3.17': 'For God sent',
            'JHN.3.18': 'He that believeth',
          },
        )
        ..passages['PSA.23.1'] = buildPassage(
          id: 'PSA.23.1',
          reference: 'Psalms 23:1',
          verses: {'PSA.23.1': 'The Lord is my shepherd'},
        );
      final cubit = build();
      await cubit.load();
      expect(passages.calls, isEmpty); // the list needs no text

      final done = cubit.loadText('x');
      expect(cubit.state.texts['x'], const SavedVerseTextLoad.loading());
      await done;

      expect(passages.bibleIds, ['web', 'web']);
      expect(passages.passageIds, ['JHN.3.16-JHN.3.18', 'PSA.23.1']);
      expect(
        cubit.state.texts['x']?.text,
        '16 For God so loved 18 He that believeth 1 The Lord is my shepherd',
      );

      await cubit.loadText('x');
      expect(passages.callCount('getPassage'), 2); // loaded once
      expect(series.calls, isEmpty); // not needed with a preference
      await cubit.close();
    });

    test('without a preference, is read in the series version', () async {
      reader
        ..preferredBibleId = null
        ..savedVerses.add(_saved('y', day: 5, verseIds: const ['PSA.23.1']));
      passages.passages['PSA.23.1'] = buildPassage(
        id: 'PSA.23.1',
        reference: 'Psalms 23:1',
        verses: {'PSA.23.1': 'The Lord is my shepherd'},
      );
      final cubit = build();
      await cubit.load();

      await cubit.loadText('y');
      expect(passages.bibleIds, ['bible-s1']);
      expect(cubit.state.texts['y']?.text, '1 The Lord is my shepherd');
      await cubit.close();
    });

    test('a failure can be retried', () async {
      reader.savedVerses.add(scattered());
      final cubit = build();
      await cubit.load();

      await cubit.loadText('x');
      expect(cubit.state.texts['x'], const SavedVerseTextLoad.failed());

      passages.passagesByBible['web/JHN.3.16-JHN.3.18'] = buildPassage(
        id: 'JHN.3.16-JHN.3.18',
        reference: 'John 3:16-18',
        bibleId: 'web',
        verses: {'JHN.3.16': 'Loved', 'JHN.3.18': 'Believes'},
      );
      passages.passagesByBible['web/PSA.23.1'] = buildPassage(
        id: 'PSA.23.1',
        reference: 'Psalms 23:1',
        bibleId: 'web',
        verses: {'PSA.23.1': 'Shepherd'},
      );
      await cubit.loadText('x');
      expect(cubit.state.texts['x']?.text, '16 Loved 18 Believes 1 Shepherd');
      await cubit.close();
    });
  });

  group('version', () {
    setUp(() {
      reader.preferredBibleId = 'web';
      passages.passages['JHN.3.16'] = buildPassage(
        id: 'JHN.3.16',
        reference: 'John 3:16',
        verses: {'JHN.3.16': 'For God so loved'},
      );
    });

    test('opening a saved verse loads the version list', () async {
      final cubit = build();
      await cubit.load();
      await cubit.loadText('a');
      await pumpEventQueue();

      expect(cubit.state.texts['a']?.bibleId, 'web');
      expect(cubit.state.preferredBibleId, 'web');
      expect(cubit.state.versions.map((v) => v.abbreviation), ['KJV', 'WEB']);
      expect(cubit.state.abbreviationOf('web'), 'WEB');
      await cubit.close();
    });

    test('choosing a version saves it, tells the reader and reloads texts',
        () async {
      final published = <PreferredBibleChanged>[];
      events.on<PreferredBibleChanged>().listen(published.add);
      final cubit = build();
      await cubit.load();
      await cubit.loadText('a');
      passages.bibleIds.clear();

      await cubit.selectBible('kjv');
      await pumpEventQueue();

      expect(reader.preferredBibleId, 'kjv');
      expect(published.map((e) => e.bibleId), ['kjv']);
      expect(passages.bibleIds, ['kjv']);
      expect(cubit.state.texts['a']?.bibleId, 'kjv');
      expect(cubit.state.texts['a']?.text, '16 For God so loved');

      // Back to each series' own version.
      await cubit.selectBible(null);
      await pumpEventQueue();
      expect(reader.preferredBibleId, isNull);
      expect(cubit.state.texts['a']?.bibleId, 'bible-s1');
      await cubit.close();
    });

    test('a text still loading in the old version is dropped', () async {
      final cubit = build();
      await cubit.load();
      final first = cubit.loadText('a'); // reads the preference: web
      await cubit.selectBible('kjv');
      await first;
      await pumpEventQueue();

      expect(cubit.state.texts['a']?.bibleId, 'kjv');
      await cubit.close();
    });

    test('a failed save keeps the version and shows an error', () async {
      reader.failOn('setPreferredBibleId');
      final cubit = build();
      await cubit.load();
      await cubit.selectBible('kjv');

      expect(cubit.state.preferredBibleId, 'kjv');
      expect(cubit.state.message, 'Unable to save your Bible version');
      expect(cubit.state.messageIsError, isTrue);
      await cubit.close();
    });

    test('follows a version chosen in the reader', () async {
      final cubit = build();
      await cubit.load();
      await cubit.loadText('a');

      events.emit(const PreferredBibleChanged('kjv'));
      await pumpEventQueue();

      expect(cubit.state.preferredBibleId, 'kjv');
      expect(cubit.state.texts['a']?.bibleId, 'kjv');
      expect(reader.calls, isNot(contains('setPreferredBibleId')));
      await cubit.close();
    });
  });
}
