import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/common/load_status.dart';
import 'package:wpa_app/application/engage/engage_home_cubit.dart';
import 'package:wpa_app/domain/achievements/entities.dart';
import 'package:wpa_app/domain/bible_series/exceptions.dart';
import 'package:wpa_app/domain/media/entities.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeBibleSeriesRepository bibleSeries;
  late FakeAchievementsRepository achievements;
  late FakeMediaRepository media;
  late FakeSession session;

  final active1 = buildSeries(id: 'a1', days: [DateTime(2026, 3, 1)]);
  final active2 = buildSeries(id: 'a2', days: [DateTime(2026, 2, 1)]);
  const video = Media(
    id: 'm1',
    description: 'Sermon',
    platform: 'YouTube',
    link: 'https://youtube.com/x',
    thumbnailUrl: 'https://img/m1',
    thumbnailGsLocation: 'gs://img/m1',
  );

  setUp(() {
    bibleSeries = FakeBibleSeriesRepository()..seriesList = [active1, active2];
    achievements = FakeAchievementsRepository();
    media = FakeMediaRepository()..media = [video];
    session = FakeSession(buildUser(firstName: 'Grace'));
  });

  EngageHomeCubit build({DateTime Function()? clock}) => EngageHomeCubit(
        bibleSeriesRepository: bibleSeries,
        achievementsRepository: achievements,
        mediaRepository: media,
        session: session,
        clock: clock,
      );

  test('with an active series: loads active series, media and progress',
      () async {
    bibleSeries.hasActive = true;
    final cubit = build();
    await cubit.load();

    final s = cubit.state;
    expect(s.status, LoadStatus.success);
    expect(s.firstName, 'Grace');
    expect(s.hasActiveSeries, isTrue);
    expect(bibleSeries.lastLimit, EngageHomeCubit.activeSeriesLimit);
    expect(bibleSeries.lastIsActive, isTrue);
    expect(s.seriesStatus, LoadStatus.success);
    expect(s.series, [active1, active2]);
    expect(s.currentSeries, active1);
    expect(s.mediaStatus, LoadStatus.success);
    expect(s.media, [video]);

    achievements.controller.add(const Achievements(seriesProgress: 42));
    await pumpEventQueue();
    expect(cubit.state.seriesProgress, 42);
    await cubit.close();
  });

  test('computes expected progress of the current series from the clock',
      () async {
    bibleSeries
      ..hasActive = true
      ..seriesList = [
        buildSeries(
            id: 'a', days: [DateTime(2026, 3, 1), DateTime(2026, 3, 2)]),
      ];
    final beforeStart = build(clock: () => DateTime(2026, 2, 28));
    await beforeStart.load();
    expect(beforeStart.state.expectedSeriesProgress, 0);

    final firstDay = build(clock: () => DateTime(2026, 3, 1, 12));
    await firstDay.load();
    expect(firstDay.state.expectedSeriesProgress, 50);
    await beforeStart.close();
    await firstDay.close();
  });

  test('without an active series: loads recent past series, no current one',
      () async {
    final cubit = build();
    await cubit.load();

    expect(cubit.state.hasActiveSeries, isFalse);
    expect(bibleSeries.lastLimit, EngageHomeCubit.pastSeriesLimit);
    expect(bibleSeries.lastIsActive, isFalse);
    expect(cubit.state.series, isNotEmpty);
    expect(cubit.state.currentSeries, isNull);
    await cubit.close();
  });

  test('a failing active check is treated as no active series', () async {
    bibleSeries.failOn('hasActiveBibleSeries');
    final cubit = build();
    await cubit.load();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.hasActiveSeries, isFalse);
    expect(bibleSeries.lastIsActive, isFalse);
    await cubit.close();
  });

  test('a series failure is reported without affecting media', () async {
    bibleSeries.failOn(
      'getBibleSeries',
      const BibleSeriesException(
        code: BibleSeriesExceptionCode.noBibleSeries,
        message: 'No bible series',
      ),
    );
    final cubit = build();
    await cubit.load();

    expect(cubit.state.seriesStatus, LoadStatus.failure);
    expect(cubit.state.seriesError, 'No bible series');
    expect(cubit.state.mediaStatus, LoadStatus.success);
    await cubit.close();
  });

  test('a media failure is reported without affecting series', () async {
    media.failOn('getAvailableMedia');
    final cubit = build();
    await cubit.load();

    expect(cubit.state.mediaStatus, LoadStatus.failure);
    expect(cubit.state.mediaError, 'Unable to load media');
    expect(cubit.state.seriesStatus, LoadStatus.success);
    await cubit.close();
  });

  test('achievement stream errors leave progress at 0', () async {
    final cubit = build();
    await cubit.load();
    achievements.controller.addError(Exception('x'));
    await pumpEventQueue();
    expect(cubit.state.seriesProgress, 0);
    await cubit.close();
  });

  test('refresh re-subscribes to achievements once (no duplicate listeners)',
      () async {
    final cubit = build();
    await cubit.load();
    await cubit.refresh();
    expect(achievements.callCount('watchAchievements'), 2);
    expect(achievements.controller.hasListener, isTrue);
    await cubit.close();
    expect(achievements.controller.hasListener, isFalse);
  });

  test('signed out shows an empty first name', () async {
    session = FakeSession();
    final cubit = build();
    await cubit.load();
    expect(cubit.state.firstName, '');
    await cubit.close();
  });
}
