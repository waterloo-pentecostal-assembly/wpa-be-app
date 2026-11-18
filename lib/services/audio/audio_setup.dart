import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

import '../../domain/audio/rules.dart';
import '../../domain/common/exceptions.dart';
import 'wpa_audio_handler.dart';

/// Starts the background audio service and returns the app's player.
///
/// - The audio session is configured for spoken word (sermons, devotionals):
///   other apps' audio pauses while ours plays, playback pauses for calls and
///   when headphones are unplugged (handled by just_audio).
/// - audio_service keeps playing when the app is in the background or
///   closed, and shows the lock screen / notification controls.
///
/// If the service cannot start (e.g. a misconfigured platform project),
/// audio still plays while the app is open; the failure is reported.
Future<WpaAudioHandler> initAudioPlayer() async {
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  } catch (e, stackTrace) {
    reportError(e, stackTrace);
  }
  try {
    return await AudioService.init(
      builder: WpaAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'church.wpassembly.beapp.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationChannelDescription:
            'Controls for the audio that is playing',
        androidNotificationIcon: 'drawable/ic_notification',
        // Stay a foreground service while paused: Android 12+ may refuse to
        // restart one from the background, which would break resuming from
        // the lock screen or a Bluetooth device. The notification's stop
        // button ends the session.
        androidStopForegroundOnPause: false,
        rewindInterval: kAudioRewindInterval,
        fastForwardInterval: kAudioFastForwardInterval,
        preloadArtwork: true,
      ),
    );
  } catch (e, stackTrace) {
    reportError(e, stackTrace);
    return WpaAudioHandler();
  }
}
