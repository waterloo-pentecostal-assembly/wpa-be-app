import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/bible_series/progress.dart';
import 'package:wpa_app/domain/completions/entities.dart';

import '../helpers/fakes.dart';

SeriesContentSnippet day(
  DateTime date, {
  bool completed = false,
  bool draft = false,
  List<AvailableContentType> contents = const [],
}) =>
    SeriesContentSnippet(
      date: date,
      isCompleted: completed,
      isDraft: draft,
      availableContentTypes: contents,
    );

BibleSeries series(List<SeriesContentSnippet> days) => BibleSeries(
      id: 's1',
      title: 'Title',
      subTitle: '',
      imageUrl: '',
      imageGsLocation: '',
      startDate: days.first.date,
      endDate: days.last.date,
      isActive: true,
      isVisible: true,
      scriptureBibleId: 'bible-1',
      seriesContentSnippet: days,
    );

void main() {
  final now = DateTime(2026, 3, 10, 9);

  group('dayStatusFor', () {
    test('completed wins over everything', () {
      expect(
        dayStatusFor(day(DateTime(2026, 3, 1), completed: true), now),
        DayStatus.completed,
      );
    });

    test('past day without completion is late', () {
      expect(dayStatusFor(day(DateTime(2026, 3, 9)), now), DayStatus.late);
    });

    test('today, future and draft days are neutral', () {
      expect(dayStatusFor(day(DateTime(2026, 3, 10)), now), DayStatus.neutral);
      expect(dayStatusFor(day(DateTime(2026, 3, 11)), now), DayStatus.neutral);
      expect(
        dayStatusFor(day(DateTime(2026, 3, 1), draft: true), now),
        DayStatus.neutral,
      );
    });
  });

  test('initialDayIndex selects today or falls back to 0', () {
    final days = [
      day(DateTime(2026, 3, 9)),
      day(DateTime(2026, 3, 10, 23)),
      day(DateTime(2026, 3, 11)),
    ];
    expect(initialDayIndex(days, now), 1);
    expect(initialDayIndex(days, DateTime(2027)), 0);
  });

  test('expectedProgress counts started days', () {
    final s = series([
      day(DateTime(2026, 3, 9)),
      day(DateTime(2026, 3, 10)),
      day(DateTime(2026, 3, 11)),
      day(DateTime(2026, 3, 12)),
    ]);
    expect(expectedProgress(s, now), 50);
  });

  group('applyCompletions', () {
    const read =
        AvailableContentType(seriesContentType: 'READ', contentId: 'r');
    const reflect =
        AvailableContentType(seriesContentType: 'REFLECT', contentId: 'q');
    final base = series([
      day(DateTime(2026, 3, 9), contents: const [read, reflect]),
    ]);

    CompletionDetails completion(String contentId, {bool draft = false}) =>
        CompletionDetails(
          id: 'c-$contentId',
          seriesId: 's1',
          contentId: contentId,
          isOnTime: true,
          isDraft: draft,
        );

    test('a completed content completes the day', () {
      final result = applyCompletions(base, {'r': completion('r')});
      final d = result.seriesContentSnippet.single;
      expect(d.isCompleted, isTrue);
      expect(d.isOnTime, isTrue);
      expect(d.isDraft, isFalse);
      expect(d.availableContentTypes.first.isCompleted, isTrue);
      expect(d.availableContentTypes.last.isCompleted, isFalse);
    });

    test('a draft only marks the day as draft', () {
      final result =
          applyCompletions(base, {'q': completion('q', draft: true)});
      final d = result.seriesContentSnippet.single;
      expect(d.isCompleted, isFalse);
      expect(d.isDraft, isTrue);
    });

    test('applyContentCompletion replaces a single content', () {
      final done = applyCompletions(base, {'r': completion('r')});
      final undone = applyContentCompletion(done, 'r', null);
      expect(undone.seriesContentSnippet.single.isCompleted, isFalse);
      expect(
        undone.seriesContentSnippet.single.availableContentTypes.first
            .isCompleted,
        isFalse,
      );
    });
  });

  test('BibleSeries.dayOf finds the 1-based day of a content', () {
    final series = buildSeries(
      days: [DateTime(2026, 3, 1), DateTime(2026, 3, 2)],
    );
    expect(series.dayOf('day0-read'), 1);
    expect(series.dayOf('day1-reflect'), 2);
    expect(series.dayOf('unknown'), isNull);
  });
}
