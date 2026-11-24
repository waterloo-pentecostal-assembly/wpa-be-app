// Widget tests of the scripture reader on the content screen: version
// picker, verse selection and the actions on selected verses.
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wpa_app/application/bible/scripture_cubit.dart';
import 'package:wpa_app/application/common/app_events.dart';
import 'package:wpa_app/application/completions/content_detail_cubit.dart';
import 'package:wpa_app/domain/bible/entities.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/presentation/design_system/theme.dart';
import 'package:wpa_app/presentation/features/bible_series/content_detail_page.dart';

import '../helpers/fakes.dart';

const _seriesId = 's1';
const _kjv = BibleVersion(
  id: 'bible-$_seriesId',
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

void main() {
  late FakeBibleSeriesRepository series;
  late FakeBiblePassageRepository passages;
  late FakeBibleReaderRepository reader;

  setUp(() {
    series = FakeBibleSeriesRepository()
      ..seriesById[_seriesId] = buildSeries(id: _seriesId, days: [])
      ..contents['read'] = SeriesContent(
        id: 'read',
        contentType: 'READ',
        date: DateTime(2026, 3, 2),
        title: 'Day 1',
        subTitle: '',
        body: const [
          ScriptureBody(passageIds: ['JHN.3.16-JHN.3.17']),
        ],
      );
    passages = FakeBiblePassageRepository()
      ..passages['JHN.3.16-JHN.3.17'] = buildPassage(
        id: 'JHN.3.16-JHN.3.17',
        reference: 'John 3:16-17',
        verses: {
          'JHN.3.16': 'For God so loved the world',
          'JHN.3.17': 'For God sent not his Son',
        },
      )
      ..passagesByBible['web/JHN.3.16'] = buildPassage(
        id: 'JHN.3.16',
        reference: 'John 3:16',
        bibleId: 'web',
        verses: {'JHN.3.16': 'For God loved the world so much'},
      );
    reader = FakeBibleReaderRepository();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ContentDetailCubit(
              bibleSeriesId: _seriesId,
              contentId: 'read',
              bibleSeriesRepository: series,
              completionsRepository: FakeCompletionsRepository(),
              analytics: FakeAnalytics(),
              events: AppEventBus(),
              session: FakeSession(buildUser(id: 'user-1')),
            )..load(),
          ),
          BlocProvider(
            create: (_) => ScriptureCubit(
              bibleSeriesId: _seriesId,
              contentId: 'read',
              bibleSeriesRepository: series,
              biblePassageRepository: passages,
              bibleVersionRepository: FakeBibleVersionRepository()
                ..versions = [_kjv, _web],
              bibleReaderRepository: reader,
              events: AppEventBus(),
            ),
          ),
        ],
        child: const ContentDetailPage(contentType: 'READ'),
      ),
    ));
    await settle(tester);
  }

  Future<void> tapVerse(WidgetTester tester, String text) async {
    await tester.tapOnText(find.textRange.ofSubstring(text));
    await settle(tester);
  }

  testWidgets('shows the passage in the series version', (tester) async {
    await pump(tester);
    expect(find.text('John 3:16-17'), findsOneWidget);
    expect(find.textContaining('For God so loved the world'), findsOneWidget);
    expect(find.text('KJV'), findsOneWidget);
    expect(find.text('Note'), findsNothing);
  });

  testWidgets('tapping verses selects them and shows the actions',
      (tester) async {
    await pump(tester);

    await tapVerse(tester, 'For God so loved');
    expect(find.text('John 3:16'), findsOneWidget);
    for (final label in ['Note', 'Save', 'Compare', 'Copy']) {
      expect(find.text(label), findsOneWidget);
    }

    await tapVerse(tester, 'sent not his Son');
    expect(find.text('John 3:16-17'), findsNWidgets(2)); // title + bar

    await tester.tap(find.byTooltip('Clear selection'));
    await settle(tester);
    expect(find.text('Note'), findsNothing);
  });

  testWidgets('save stores the selected verses', (tester) async {
    await pump(tester);
    await tapVerse(tester, 'For God so loved');

    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(reader.savedVerses.single.note, isNull);
    expect(reader.savedVerses.single.verseIds, ['JHN.3.16']);
    expect(find.text('Save'), findsNothing); // selection cleared

    await tapVerse(tester, 'For God so loved');
    expect(find.text('Unsave'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // toasts expire
  });

  testWidgets('a note is written, shown and edited', (tester) async {
    await pump(tester);
    await tapVerse(tester, 'sent not his Son');

    await tester.tap(find.text('Note'));
    await settle(tester);
    expect(find.text('John 3:17 (KJV)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'He came to save');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    expect(reader.savedVerses.single.note, 'He came to save');
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byIcon(Icons.sticky_note_2_outlined));
    await settle(tester);
    expect(find.text('He came to save'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Not to condemn');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(reader.savedVerses.single.note, 'Not to condemn');
    await tester.pump(const Duration(seconds: 4)); // toasts expire
  });

  testWidgets('a note on a saved verse updates it instead of adding one',
      (tester) async {
    await pump(tester);
    await tapVerse(tester, 'For God so loved');
    await tester.tap(find.text('Save'));
    await settle(tester);

    await tapVerse(tester, 'For God so loved');
    await tester.tap(find.text('Note'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Love');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    expect(reader.savedVerses, hasLength(1));
    expect(reader.savedVerses.single.note, 'Love');
    expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // toasts expire
  });

  testWidgets('deleting a note keeps the verse saved', (tester) async {
    await pump(tester);
    await tapVerse(tester, 'For God so loved');
    await tester.tap(find.text('Note'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Love');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.sticky_note_2_outlined));
    await settle(tester);
    await tester.tap(find.byTooltip('Delete note'));
    await settle(tester);
    expect(
        find.text('Delete this note? The verses stay saved.'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await settle(tester);

    expect(reader.savedVerses.single.note, isNull);
    expect(find.byIcon(Icons.sticky_note_2_outlined), findsNothing);
    await tapVerse(tester, 'For God so loved');
    expect(find.text('Unsave'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // toasts expire
  });

  testWidgets('unsaving a verse with a note asks first', (tester) async {
    await pump(tester);
    await tapVerse(tester, 'For God so loved');
    await tester.tap(find.text('Note'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Love');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    await tapVerse(tester, 'For God so loved');
    await tester.tap(find.text('Unsave'));
    await settle(tester);
    expect(find.text('Your note on John 3:16 will be deleted too.'),
        findsOneWidget);
    await tester.tap(find.text('No'));
    await settle(tester);
    expect(reader.savedVerses, hasLength(1));

    await tester.tap(find.text('Unsave'));
    await settle(tester);
    await tester.tap(find.text('Yes'));
    await settle(tester);
    expect(reader.savedVerses, isEmpty);
    await tester.pump(const Duration(seconds: 4)); // toasts expire
  });

  testWidgets('compare shows the verses in another version', (tester) async {
    await pump(tester);
    await tapVerse(tester, 'For God so loved');

    await tester.tap(find.text('Compare'));
    await settle(tester);

    expect(find.text('Compare John 3:16'), findsOneWidget);
    expect(find.text('WEB'), findsOneWidget);
    expect(
      find.textContaining('For God loved the world so much'),
      findsOneWidget,
    );
  });

  testWidgets('choosing a version reloads the passage in it', (tester) async {
    passages.passagesByBible['web/JHN.3.16-JHN.3.17'] = buildPassage(
      id: 'JHN.3.16-JHN.3.17',
      reference: 'John 3:16-17',
      bibleId: 'web',
      verses: {'JHN.3.16': 'For God loved', 'JHN.3.17': 'God sent'},
    );
    await pump(tester);

    await tester.tap(find.text('KJV'));
    await settle(tester);
    expect(find.text('Bible version'), findsOneWidget);
    expect(find.text('Series version'), findsOneWidget);
    await tester.tap(find.text('World English Bible'));
    await settle(tester);

    expect(reader.preferredBibleId, 'web');
    expect(find.text('WEB'), findsOneWidget);
    expect(find.textContaining('For God so loved'), findsNothing);
    expect(find.textContaining('For God loved'), findsOneWidget);
  });

  testWidgets('a saved verse shows in whichever version is read',
      (tester) async {
    passages.passagesByBible['web/JHN.3.16-JHN.3.17'] = buildPassage(
      id: 'JHN.3.16-JHN.3.17',
      reference: 'John 3:16-17',
      bibleId: 'web',
      verses: {'JHN.3.16': 'For God loved', 'JHN.3.17': 'God sent'},
    );
    reader.savedVerses.add(SavedVerse(
      id: 'n1',
      verseIds: const ['JHN.3.16'],
      reference: 'John 3:16',
      seriesId: _seriesId,
      contentId: 'read',
      note: 'Love',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ));
    await pump(tester);
    expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);

    Future<void> choose(String version) async {
      await tester.tap(find.text(version == 'Series version' ? 'WEB' : 'KJV'));
      await settle(tester);
      await tester.tap(find.text(version));
      await settle(tester);
    }

    await choose('World English Bible');
    expect(find.textContaining('For God loved'), findsOneWidget);
    expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);

    await choose('Series version');
    expect(find.textContaining('For God so loved'), findsOneWidget);
    expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);
  });
}

/// Pumps frames without waiting for endless animations (loading dots).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
