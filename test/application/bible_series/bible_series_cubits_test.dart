import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/bible_series/all_bible_series_cubit.dart';
import 'package:wpa_app/application/bible_series/bible_series_detail_cubit.dart';
import 'package:wpa_app/application/common/app_events.dart';
import 'package:wpa_app/application/common/load_status.dart';
import 'package:wpa_app/domain/bible_series/progress.dart';
import 'package:wpa_app/domain/common/analytics.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeBibleSeriesRepository bibleSeries;

  setUp(() => bibleSeries = FakeBibleSeriesRepository());

  group('AllBibleSeriesCubit', () {
    final s1 = buildSeries(id: 's1', days: [DateTime(2026, 1, 1)]);
    final s2 = buildSeries(id: 's2', days: [DateTime(2025, 1, 1)]);

    blocTest<AllBibleSeriesCubit, AllBibleSeriesState>(
      'loads the most recent series',
      build: () {
        bibleSeries.seriesList = [s1, s2];
        return AllBibleSeriesCubit(bibleSeries);
      },
      act: (c) => c.load(),
      expect: () => [
        const AllBibleSeriesState(status: LoadStatus.loading),
        AllBibleSeriesState(status: LoadStatus.success, series: [s1, s2]),
      ],
      verify: (_) {
        expect(bibleSeries.lastLimit, AllBibleSeriesCubit.limit);
        expect(bibleSeries.lastIsActive, isFalse);
      },
    );

    blocTest<AllBibleSeriesCubit, AllBibleSeriesState>(
      'reports a failure with the user-safe message',
      build: () {
        bibleSeries.failOn('getBibleSeries');
        return AllBibleSeriesCubit(bibleSeries);
      },
      act: (c) => c.load(),
      expect: () => [
        const AllBibleSeriesState(status: LoadStatus.loading),
        const AllBibleSeriesState(
          status: LoadStatus.failure,
          errorMessage: 'Fake failure',
        ),
      ],
    );
  });

  group('BibleSeriesDetailCubit', () {
    late FakeCompletionsRepository completions;
    late FakeAnalytics analytics;
    late AppEventBus events;

    // Clock: 2 March 2026, 10:00 local. Series runs 1-3 March.
    final now = DateTime(2026, 3, 2, 10);
    final series = buildSeries(days: [
      DateTime(2026, 3, 1),
      DateTime(2026, 3, 2),
      DateTime(2026, 3, 3),
    ]);

    setUp(() {
      completions = FakeCompletionsRepository();
      analytics = FakeAnalytics();
      events = AppEventBus();
      bibleSeries.seriesById[series.id] = series;
    });

    tearDown(() => events.dispose());

    BibleSeriesDetailCubit build({DateTime? at}) => BibleSeriesDetailCubit(
          bibleSeriesId: series.id,
          bibleSeriesRepository: bibleSeries,
          completionsRepository: completions,
          analytics: analytics,
          events: events,
          clock: () => at ?? now,
        );

    test('load logs bible_series_viewed and applies completions', () async {
      completions.completions['day1-reflect'] =
          buildCompletion('day1-reflect', isDraft: true);
      completions.completions['day2-read'] = buildCompletion('day2-read');
      // A completion of another series must not leak in.
      completions.completions['day0-read'] =
          buildCompletion('day0-read', seriesId: 'other');

      final cubit = build();
      await cubit.load();

      expect(analytics.names, [AnalyticsEvents.bibleSeriesViewed]);
      final s = cubit.state;
      expect(s.status, LoadStatus.success);
      final days = s.series!.seriesContentSnippet;
      expect(days[0].isCompleted, isFalse);
      expect(days[0].isDraft, isFalse);
      expect(days[1].isCompleted, isFalse);
      expect(days[1].isDraft, isTrue);
      expect(days[1].availableContentTypes[1].isDraft, isTrue);
      expect(days[2].isCompleted, isTrue);
      expect(days[2].isOnTime, isTrue);
      expect(days[2].availableContentTypes[0].isCompleted, isTrue);
      expect(days[2].availableContentTypes[1].isCompleted, isFalse);
      await cubit.close();
    });

    test('initial day is today according to the injected clock', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.initialDayIndex, 1);
      await cubit.close();
    });

    test('initial day falls back to the first day outside the series',
        () async {
      final cubit = build(at: DateTime(2026, 6, 1));
      await cubit.load();
      expect(cubit.state.initialDayIndex, 0);
      await cubit.close();
    });

    test('dayStatus and isToday are evaluated against the clock', () async {
      completions.completions['day2-read'] = buildCompletion('day2-read');
      final cubit = build();
      await cubit.load();
      final days = cubit.state.series!.seriesContentSnippet;

      expect(cubit.dayStatus(days[0]), DayStatus.late);
      expect(cubit.dayStatus(days[1]), DayStatus.neutral);
      expect(cubit.dayStatus(days[2]), DayStatus.completed);
      expect(cubit.isToday(days[0]), isFalse);
      expect(cubit.isToday(days[1]), isTrue);
      await cubit.close();
    });

    test('load failure reports the error (and still logs the view)', () async {
      bibleSeries.seriesById.clear();
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.errorMessage, 'Bible series not found');
      expect(cubit.state.series, isNull);
      expect(analytics.names, [AnalyticsEvents.bibleSeriesViewed]);
      await cubit.close();
    });

    test('CompletionChanged for this series refreshes that content', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.series!.seriesContentSnippet[0].isCompleted, isFalse);

      completions.completions['day0-read'] =
          buildCompletion('day0-read', isOnTime: false);
      events
          .emit(CompletionChanged(seriesId: series.id, contentId: 'day0-read'));
      await pumpEventQueue();

      final day0 = cubit.state.series!.seriesContentSnippet[0];
      expect(day0.isCompleted, isTrue);
      expect(day0.isOnTime, isFalse);
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.dayStatus(day0), DayStatus.completed);
      await cubit.close();
    });

    test('CompletionChanged reverting a completion clears the flags', () async {
      completions.completions['day0-read'] = buildCompletion('day0-read');
      final cubit = build();
      await cubit.load();
      expect(cubit.state.series!.seriesContentSnippet[0].isCompleted, isTrue);

      completions.completions.remove('day0-read');
      events
          .emit(CompletionChanged(seriesId: series.id, contentId: 'day0-read'));
      await pumpEventQueue();

      expect(cubit.state.series!.seriesContentSnippet[0].isCompleted, isFalse);
      await cubit.close();
    });

    test('CompletionChanged for another series is ignored', () async {
      final cubit = build();
      await cubit.load();
      final before = completions.callCount('getCompletionOrNull');

      events.emit(
          const CompletionChanged(seriesId: 'other', contentId: 'day0-read'));
      await pumpEventQueue();

      expect(completions.callCount('getCompletionOrNull'), before);
      await cubit.close();
    });

    test('refreshContent before load is a no-op', () async {
      final cubit = build();
      await cubit.refreshContent('day0-read');
      expect(cubit.state.status, LoadStatus.initial);
      expect(completions.callCount('getCompletionOrNull'), 0);
      await cubit.close();
    });

    test('refreshContent failure keeps the current series', () async {
      final cubit = build();
      await cubit.load();
      final before = cubit.state;
      completions.failOn('getCompletionOrNull');
      await cubit.refreshContent('day0-read');
      expect(cubit.state, before);
      await cubit.close();
    });

    test('stops listening to the bus once closed', () async {
      final cubit = build();
      await cubit.load();
      await cubit.close();
      expect(
        () => events.emit(
            CompletionChanged(seriesId: series.id, contentId: 'day0-read')),
        returnsNormally,
      );
      expect(completions.callCount('getCompletionOrNull'), 0);
    });
  });
}
