import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/audio_player/audio_player_cubit.dart';
import 'package:wpa_app/domain/audio/entities.dart';
import 'package:wpa_app/domain/audio/exceptions.dart';
import 'package:wpa_app/domain/common/error_reporting.dart';

import '../../helpers/fakes.dart';

const _sermon = AudioTrack(
  id: 'c1/0',
  url: 'https://example.com/sermon.mp3',
  title: 'Sermon',
  origin: AudioTrackOrigin(seriesId: 's1', contentId: 'c1'),
);
const _devotional = AudioTrack(
  id: 'c2/0',
  url: 'https://example.com/devotional.mp3',
  title: 'Devotional',
  origin: AudioTrackOrigin(seriesId: 's1', contentId: 'c2'),
);

void main() {
  late FakeAudioPlayer player;
  late AudioPlayerCubit cubit;

  setUp(() {
    player = FakeAudioPlayer();
    cubit = AudioPlayerCubit(player);
  });

  tearDown(() => cubit.close());

  test('starts from what the player is already doing (e.g. background)', () {
    player
      ..emit(const AudioPlayback(
        track: _sermon,
        processing: AudioProcessing.ready,
        playing: true,
        duration: Duration(minutes: 3),
      ))
      ..emitPosition(const Duration(seconds: 42));

    final fresh = AudioPlayerCubit(player);
    addTearDown(fresh.close);

    expect(fresh.state.track, _sermon);
    expect(fresh.state.isPlaying, isTrue);
    expect(fresh.state.position, const Duration(seconds: 42));
  });

  test('play loads the track, then plays it', () async {
    await cubit.play(_sermon);

    expect(player.calls, ['load', 'play']);
    expect(cubit.state.track, _sermon);
    expect(cubit.state.isPlaying, isTrue);
    expect(cubit.state.duration, const Duration(minutes: 3));
    expect(cubit.state.isPlayingContent('c1'), isTrue);
    expect(cubit.state.isPlayingContent('c2'), isFalse);
  });

  test('toggle pauses the current track and resumes without reloading',
      () async {
    await cubit.toggle(_sermon);
    await cubit.toggle(_sermon);
    expect(cubit.state.isPlaying, isFalse);

    await cubit.toggle(_sermon);
    expect(player.calls, ['load', 'play', 'pause', 'play']);
    expect(cubit.state.isPlaying, isTrue);
  });

  test('playing another track loads it and resets the position', () async {
    await cubit.play(_sermon);
    player.emitPosition(const Duration(minutes: 1));

    await cubit.play(_devotional);

    expect(player.loaded, [_sermon, _devotional]);
    expect(cubit.state.track, _devotional);
    expect(cubit.state.position, Duration.zero);
  });

  test('a load failure shows the message and is recorded', () async {
    final recorded = <Object>[];
    ErrorHooks.install(record: (e, _) => recorded.add(e));
    addTearDown(ErrorHooks.reset);
    const failure = AudioPlaybackException(
      code: AudioPlaybackExceptionCode.unableToLoad,
      details: 'network down',
    );
    player.failOn('load', failure);

    await cubit.play(_sermon);

    expect(cubit.state.error, kAudioPlaybackErrorMessage);
    expect(player.calls, ['load']);
    expect(recorded, [failure]);
  });

  test('retrying after a playback error reloads the track', () async {
    await cubit.play(_sermon);
    player.emit(const AudioPlayback(
      track: _sermon,
      processing: AudioProcessing.ready,
      errorMessage: kAudioPlaybackErrorMessage,
    ));

    await cubit.play(_sermon);

    expect(player.loaded, [_sermon, _sermon]);
  });

  test('the next action clears a previous action error', () async {
    player.failOn('pause');
    await cubit.pause();
    expect(cubit.state.actionError, isNotNull);

    player.succeedOn('pause');
    await cubit.pause();
    expect(cubit.state.actionError, isNull);
  });

  test('seek is clamped to the track duration', () async {
    await cubit.play(_sermon);
    await cubit.seek(const Duration(minutes: 10));
    await cubit.seek(const Duration(seconds: -1));
    expect(player.seeks, [const Duration(minutes: 3), Duration.zero]);
  });

  test('skip buttons delegate to the player', () async {
    await cubit.play(_sermon);
    await cubit.skipForward();
    await cubit.skipBackward();
    expect(player.calls.skip(2), ['skipForward', 'skipBackward']);
  });

  test('the speed button cycles through the speeds', () async {
    await cubit.play(_sermon);
    await cubit.cycleSpeed();
    expect(cubit.state.speed, 1.25);
    await cubit.cycleSpeed();
    expect(cubit.state.speed, 1.5);
  });

  test('stop unloads the track', () async {
    await cubit.play(_sermon);
    await cubit.stop();
    expect(cubit.state.hasTrack, isFalse);
    expect(cubit.state.isPlaying, isFalse);
  });

  test('closing the cubit does not stop playback', () async {
    await cubit.play(_sermon);
    await cubit.close();
    expect(player.calls, isNot(contains('stop')));
    expect(player.playback.playing, isTrue);
  });

  test('position updates are reflected', () async {
    await cubit.play(_sermon);
    player.emitPosition(const Duration(seconds: 30));
    expect(cubit.state.position, const Duration(seconds: 30));
  });

  test('loading / buffering while playing shows as loading', () {
    player.emit(const AudioPlayback(
      track: _sermon,
      processing: AudioProcessing.buffering,
      playing: true,
    ));
    expect(cubit.state.isLoading, isTrue);
    expect(cubit.state.isPlaying, isTrue);

    player.emit(const AudioPlayback(
      track: _sermon,
      processing: AudioProcessing.buffering,
    ));
    expect(cubit.state.isLoading, isFalse);
  });
}
