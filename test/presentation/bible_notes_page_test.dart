// Widget tests of the profile's saved verses (and notes) screen.
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/application/bible/bible_notes_cubit.dart';
import 'package:wpa_app/application/common/app_events.dart';
import 'package:wpa_app/domain/bible/entities.dart';
import 'package:wpa_app/presentation/design_system/theme.dart';
import 'package:wpa_app/presentation/features/bible_notes/bible_notes_page.dart';
import 'package:wpa_app/presentation/foundation/navigation/app_navigator.dart';

import '../helpers/fakes.dart';

class _MockNavigator extends Mock implements AppNavigator {}

void main() {
  late FakeBibleReaderRepository reader;
  late FakeBiblePassageRepository passages;
  late _MockNavigator navigator;

  SavedVerse savedOf(String reference) =>
      reader.savedVerses.firstWhere((v) => v.reference == reference);

  setUp(() async {
    reader = FakeBibleReaderRepository();
    passages = FakeBiblePassageRepository()
      ..passages['JHN.3.16'] = buildPassage(
        id: 'JHN.3.16',
        reference: 'John 3:16',
        verses: {'JHN.3.16': 'For God so loved the world'},
      );
    navigator = _MockNavigator();
    await reader.addSavedVerse(const NewSavedVerse(
      verseIds: ['JHN.3.16'],
      reference: 'John 3:16',
      bibleId: 'kjv',
      versionAbbreviation: 'KJV',
      note: 'Love first',
      seriesId: 's1',
      contentId: 'c1',
      seriesTitle: 'Hope in Hard Times',
      day: 3,
    ));
    await reader.addSavedVerse(const NewSavedVerse(
      verseIds: ['PSA.23.1'],
      reference: 'Psalms 23:1',
      bibleId: 'kjv',
      versionAbbreviation: 'KJV',
      seriesId: 's2',
      contentId: 'c7',
    ));
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepositoryProvider<AppNavigator>.value(
      value: navigator,
      child: MaterialApp(
        theme: buildAppTheme(),
        home: BlocProvider(
          create: (_) => BibleNotesCubit(
            bibleReaderRepository: reader,
            biblePassageRepository: passages,
            events: AppEventBus(),
          )..load(),
          child: const BibleNotesPage(),
        ),
      ),
    ));
    await settle(tester);
  }

  Future<void> writeNote(WidgetTester tester, String note) async {
    await tester.enterText(find.byType(TextField), note);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
  }

  testWidgets('lists saved verses with their notes, and filters',
      (tester) async {
    await pump(tester);
    expect(find.text('John 3:16 (KJV)'), findsOneWidget);
    expect(find.text('Love first'), findsOneWidget);
    expect(find.text('Psalms 23:1 (KJV)'), findsOneWidget);
    expect(find.text('Hope in Hard Times · Day 3'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'With notes'));
    await settle(tester);
    expect(find.text('John 3:16 (KJV)'), findsOneWidget);
    expect(find.text('Psalms 23:1 (KJV)'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await settle(tester);
    expect(find.text('Psalms 23:1 (KJV)'), findsOneWidget);
  });

  testWidgets('shows an empty state', (tester) async {
    reader.savedVerses.clear();
    await pump(tester);
    expect(find.textContaining('No saved verses yet'), findsOneWidget);
  });

  testWidgets('the list shows no verse text and makes no API calls',
      (tester) async {
    await pump(tester);
    expect(find.textContaining('For God so loved'), findsNothing);
    expect(passages.calls, isEmpty);
  });

  testWidgets('details load the verses in the saved version', (tester) async {
    await pump(tester);
    await tester.tap(find.text('John 3:16 (KJV)'));
    await settle(tester);

    expect(find.text('16 For God so loved the world'), findsOneWidget);
    expect(passages.bibleIds, ['kjv']);
    expect(find.text('Hope in Hard Times · Day 3'), findsNWidgets(2));
  });

  testWidgets('details show Retry when the verses fail to load',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Psalms 23:1 (KJV)')); // not in the fake
    await settle(tester);
    expect(find.text('Unable to load scripture'), findsOneWidget);

    passages.passages['PSA.23.1'] = buildPassage(
      id: 'PSA.23.1',
      reference: 'Psalms 23:1',
      verses: {'PSA.23.1': 'The Lord is my shepherd'},
    );
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.text('1 The Lord is my shepherd'), findsOneWidget);
  });

  testWidgets('adding a note updates the same saved verse', (tester) async {
    passages.passages['PSA.23.1'] = buildPassage(
      id: 'PSA.23.1',
      reference: 'Psalms 23:1',
      verses: {'PSA.23.1': 'The Lord is my shepherd'},
    );
    await pump(tester);
    await tester.tap(find.text('Psalms 23:1 (KJV)'));
    await settle(tester);
    expect(find.text('Edit note'), findsNothing);

    await tester.tap(find.text('Add note'));
    await settle(tester);
    expect(find.text('1 The Lord is my shepherd'), findsNWidgets(2)); // quote
    await writeNote(tester, 'He leads me');

    expect(reader.savedVerses, hasLength(2)); // no new record
    expect(savedOf('Psalms 23:1').note, 'He leads me');
    // The details sheet stays open and now shows the note.
    expect(find.text('Edit note'), findsOneWidget);
    expect(find.text('He leads me'), findsNWidgets(2)); // list + sheet
    expect(find.text('Psalms 23:1 (KJV)'), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 4)); // toasts expire
  });

  testWidgets('a note can be edited and deleted, keeping the save',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('John 3:16 (KJV)'));
    await settle(tester);
    expect(find.text('Open reading'), findsOneWidget);

    await tester.tap(find.text('Edit note'));
    await settle(tester);
    await writeNote(tester, 'Love always');
    expect(savedOf('John 3:16').note, 'Love always');

    await tester.tap(find.text('Edit note'));
    await settle(tester);
    await tester.tap(find.byTooltip('Delete note'));
    await settle(tester);
    await tester.tap(find.text('Yes'));
    await settle(tester);

    expect(savedOf('John 3:16').note, isNull);
    expect(find.text('Add note'), findsOneWidget);
    expect(find.text('Love always'), findsNothing);
    await tester.pump(const Duration(seconds: 4)); // toasts expire
  });

  testWidgets('removing asks first and mentions the note', (tester) async {
    await pump(tester);
    await tester.tap(find.text('John 3:16 (KJV)'));
    await settle(tester);

    await tester.tap(find.text('Remove'));
    await settle(tester);
    expect(
      find.text('Remove John 3:16 from your saved verses? Your note will be '
          'deleted too.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Yes'));
    await settle(tester);

    expect(reader.savedVerses.map((v) => v.reference), ['Psalms 23:1']);
    expect(find.text('John 3:16 (KJV)'), findsNothing);
    await tester.pump(const Duration(seconds: 4)); // toasts expire
  });

  testWidgets('open reading goes to the series content', (tester) async {
    await pump(tester);
    await tester.tap(find.text('John 3:16 (KJV)'));
    await settle(tester);
    await tester.tap(find.text('Open reading'));
    await settle(tester);

    verify(() => navigator.openContent(seriesId: 's1', contentId: 'c1'))
        .called(1);
  });
}

/// Pumps frames without waiting for endless animations (loading dots).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
