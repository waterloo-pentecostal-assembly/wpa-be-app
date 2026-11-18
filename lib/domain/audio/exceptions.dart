import '../common/exceptions.dart';

enum AudioPlaybackExceptionCode { unableToLoad, playbackFailed }

/// Shown when a track cannot be loaded or stops with an error.
const kAudioPlaybackErrorMessage =
    "This audio couldn't be played. Check your connection and try again.";

class AudioPlaybackException
    extends BaseApplicationException<AudioPlaybackExceptionCode> {
  const AudioPlaybackException({
    required super.code,
    super.message = kAudioPlaybackErrorMessage,
    super.details,
  });
}
