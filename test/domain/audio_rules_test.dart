import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/audio/rules.dart';

void main() {
  test('nextPlaybackSpeed cycles through the speeds and wraps around', () {
    var speed = 1.0;
    final seen = <double>[];
    for (var i = 0; i < kAudioPlaybackSpeeds.length; i++) {
      speed = nextPlaybackSpeed(speed);
      seen.add(speed);
    }
    expect(seen, [1.25, 1.5, 2.0, 0.75, 1.0]);
    expect(nextPlaybackSpeed(3.0), 1.0); // unknown speed restarts at 1x
  });

  test('clampToTrack keeps positions inside the track', () {
    const duration = Duration(minutes: 3);
    expect(clampToTrack(const Duration(seconds: -1), duration), Duration.zero);
    expect(clampToTrack(const Duration(minutes: 4), duration), duration);
    expect(clampToTrack(const Duration(minutes: 1), duration),
        const Duration(minutes: 1));
    expect(
        clampToTrack(const Duration(hours: 2), null), const Duration(hours: 2));
  });
}
