/// Jump of the "back" button (app, lock screen, notification).
const kAudioRewindInterval = Duration(seconds: 10);

/// Jump of the "forward" button (app, lock screen, notification).
const kAudioFastForwardInterval = Duration(seconds: 30);

/// Playback speeds, in the order the speed button cycles through them.
const kAudioPlaybackSpeeds = [1.0, 1.25, 1.5, 2.0, 0.75];

/// The speed after [current] in [kAudioPlaybackSpeeds] (1x for unknown).
double nextPlaybackSpeed(double current) {
  final index = kAudioPlaybackSpeeds.indexOf(current);
  return kAudioPlaybackSpeeds[(index + 1) % kAudioPlaybackSpeeds.length];
}

/// [position] kept within `[0, duration]` (no upper bound if unknown).
Duration clampToTrack(Duration position, Duration? duration) {
  if (position < Duration.zero) return Duration.zero;
  if (duration != null && position > duration) return duration;
  return position;
}
