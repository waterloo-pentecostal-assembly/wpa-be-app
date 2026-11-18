import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wpa_app/application/audio_player/audio_player_cubit.dart';
import 'package:wpa_app/domain/audio/entities.dart';
import 'package:wpa_app/domain/audio/exceptions.dart';
import 'package:wpa_app/presentation/design_system/theme.dart';
import 'package:wpa_app/presentation/features/audio/audio_player_card.dart';
import 'package:wpa_app/presentation/features/audio/audio_seek_bar.dart';
import 'package:wpa_app/presentation/features/audio/mini_player.dart';
import 'package:wpa_app/presentation/foundation/navigation/app_navigator.dart';

import '../helpers/fakes.dart';

class _MockNavigator extends Mock implements AppNavigator {}

const _track = AudioTrack(
  id: 'c1/0',
  url: 'https://example.com/sermon.mp3',
  title: 'Sunday sermon',
  subtitle: 'Day 1 · Gospel of John',
  origin: AudioTrackOrigin(
    seriesId: 's1',
    contentId: 'c1',
    contentType: 'LISTEN',
  ),
);

void main() {
  late FakeAudioPlayer player;
  late AudioPlayerCubit cubit;
  late _MockNavigator navigator;

  // Created inside each test (not in setUp) so stream events run in the
  // test's fake-async zone.
  void start() {
    player = FakeAudioPlayer();
    cubit = AudioPlayerCubit(player);
    navigator = _MockNavigator();
    addTearDown(cubit.close);
  }

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 390,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      RepositoryProvider<AppNavigator>.value(
        value: navigator,
        child: BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  group('AudioSeekBar', () {
    testWidgets('seeks once, on release, to the dragged position',
        (tester) async {
      start();
      final seeks = <Duration>[];
      await pump(
        tester,
        Center(
          child: AudioSeekBar(
            position: Duration.zero,
            duration: const Duration(minutes: 10),
            onSeek: seeks.add,
          ),
        ),
      );

      final slider = find.byType(Slider);
      final gesture = await tester.startGesture(tester.getCenter(slider));
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      expect(seeks, isEmpty, reason: 'no seek while dragging');

      await gesture.up();
      await tester.pump();
      expect(seeks, hasLength(1));
      expect(seeks.single, greaterThan(const Duration(minutes: 5)));
    });

    testWidgets('shows elapsed and remaining time', (tester) async {
      start();
      await pump(
        tester,
        const AudioSeekBar(
          position: Duration(minutes: 1, seconds: 5),
          duration: Duration(hours: 1, minutes: 1, seconds: 5),
        ),
      );
      expect(find.text('1:05'), findsOneWidget);
      expect(find.text('-1:00:00'), findsOneWidget);
    });

    testWidgets('is disabled while the duration is unknown', (tester) async {
      start();
      await pump(
        tester,
        AudioSeekBar(
          position: Duration.zero,
          duration: Duration.zero,
          onSeek: (_) {},
        ),
      );
      expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
      expect(find.text('--:--'), findsOneWidget);
    });
  });

  group('AudioPlayerCard', () {
    testWidgets('play loads the track; controls enable once it is current',
        (tester) async {
      start();
      await pump(tester, const AudioPlayerCard(track: _track));

      expect(find.text('Sunday sermon'), findsOneWidget);
      expect(find.text('Day 1 · Gospel of John'), findsOneWidget);
      IconButton forward() => tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.forward_30));
      expect(forward().onPressed, isNull);

      await tester.tap(find.byTooltip('Play'));
      await tester.pump();

      expect(player.loaded, [_track]);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(forward().onPressed, isNotNull);

      await tester.tap(find.byTooltip('Forward 30 seconds'));
      await tester.tap(find.byTooltip('Back 10 seconds'));
      await tester.pump();
      expect(player.calls, containsAllInOrder(['skipForward', 'skipBackward']));

      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(find.byTooltip('Play'), findsOneWidget);
    });

    testWidgets('the speed button cycles the playback speed', (tester) async {
      start();
      await pump(tester, const AudioPlayerCard(track: _track));
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();

      expect(find.text('1x'), findsOneWidget);
      await tester.tap(find.text('1x'));
      await tester.pump();
      expect(find.text('1.25x'), findsOneWidget);
    });

    testWidgets('shows a spinner while loading', (tester) async {
      start();
      player.emit(const AudioPlayback(
        track: _track,
        processing: AudioProcessing.loading,
        playing: true,
      ));
      await pump(tester, const AudioPlayerCard(track: _track));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('an error shows the message and Retry reloads', (tester) async {
      start();
      player.failOn(
        'load',
        const AudioPlaybackException(
          code: AudioPlaybackExceptionCode.unableToLoad,
        ),
      );
      await pump(tester, const AudioPlayerCard(track: _track));
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      expect(find.text(kAudioPlaybackErrorMessage), findsOneWidget);

      player.succeedOn('load');
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(player.loaded, [_track, _track]);
      expect(find.text(kAudioPlaybackErrorMessage), findsNothing);
    });

    testWidgets('another track playing leaves this card idle', (tester) async {
      start();
      player.emit(const AudioPlayback(
        track: AudioTrack(id: 'other', url: 'u', title: 'Other'),
        processing: AudioProcessing.ready,
        playing: true,
        duration: Duration(minutes: 3),
      ));
      await pump(tester, const AudioPlayerCard(track: _track));
      expect(find.byTooltip('Play'), findsOneWidget);
      expect(find.text('--:--'), findsOneWidget);
    });

    testWidgets('fits a phone at 200% text', (tester) async {
      start();
      await pump(
        tester,
        const SingleChildScrollView(child: AudioPlayerCard(track: _track)),
        width: 320,
        textScale: 2,
      );
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('MiniPlayer', () {
    Widget shell() => const Column(
          children: [Expanded(child: SizedBox()), MiniPlayer()],
        );

    testWidgets('is hidden until a track is loaded', (tester) async {
      start();
      await pump(tester, shell());
      expect(find.text('Sunday sermon'), findsNothing);

      await cubit.play(_track);
      await tester.pumpAndSettle();
      expect(find.text('Sunday sermon'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
    });

    testWidgets('play/pause and stop', (tester) async {
      start();
      await cubit.play(_track);
      await pump(tester, shell());

      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(player.playback.playing, isFalse);

      await tester.tap(find.byTooltip('Stop'));
      await tester.pumpAndSettle();
      expect(player.calls, contains('stop'));
      expect(find.text('Sunday sermon'), findsNothing);
    });

    testWidgets('tapping it opens the content the track came from',
        (tester) async {
      start();
      await cubit.play(_track);
      await pump(tester, shell());

      await tester.tap(find.text('Sunday sermon'));
      verify(() => navigator.openContent(
            seriesId: 's1',
            contentId: 'c1',
            contentType: 'LISTEN',
          )).called(1);
    });
  });
}
