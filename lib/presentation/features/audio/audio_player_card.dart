import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/audio_player/audio_player_cubit.dart';
import '../../../domain/audio/entities.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import 'audio_seek_bar.dart';

/// Full player for one [track]: title, scrubbable progress, back 10 s,
/// play/pause, forward 30 s and playback speed. Controls other than play
/// are enabled once this track is the current one. Playback is app-wide, so
/// it continues when leaving the page or the app.
class AudioPlayerCard extends StatelessWidget {
  const AudioPlayerCard({super.key, required this.track});

  final AudioTrack track;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AudioPlayerCubit>();
    final state = context.watch<AudioPlayerCubit>().state;
    final isCurrent = state.isCurrent(track.id);
    final isPlaying = isCurrent && state.isPlaying;
    final isLoading = isCurrent && state.isLoading;
    final error = isCurrent ? state.error : null;
    final subtitle = track.subtitle;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardOverlayGrey,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                Text(
                  track.title,
                  style: context.text.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: context.textStyles.muted,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AudioSeekBar(
            position: isCurrent ? state.position : Duration.zero,
            duration: isCurrent ? state.duration : Duration.zero,
            bufferedPosition:
                isCurrent ? state.bufferedPosition : Duration.zero,
            onSeek: isCurrent ? cubit.seek : null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Back 10 seconds',
                iconSize: 34,
                icon: const Icon(Icons.replay_10),
                onPressed: isCurrent ? cubit.skipBackward : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              PlayPauseButton(
                isPlaying: isPlaying,
                isLoading: isLoading,
                size: 64,
                onPressed: () => cubit.toggle(track),
              ),
              const SizedBox(width: AppSpacing.lg),
              IconButton(
                tooltip: 'Forward 30 seconds',
                iconSize: 34,
                icon: const Icon(Icons.forward_30),
                onPressed: isCurrent ? cubit.skipForward : null,
              ),
            ],
          ),
          _SpeedButton(
            speed: isCurrent ? state.speed : 1.0,
            onPressed: isCurrent ? cubit.cycleSpeed : null,
          ),
          if (error != null)
            _ErrorRow(message: error, onRetry: () => cubit.play(track)),
        ],
      ),
    );
  }
}

/// Round play/pause button that shows a spinner while loading.
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.onPressed,
    this.size = 48,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox.square(
        dimension: size,
        child: Padding(
          padding: EdgeInsets.all(size / 4),
          child: const CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    }
    return IconButton(
      tooltip: isPlaying ? 'Pause' : 'Play',
      iconSize: size,
      padding: EdgeInsets.zero,
      color: AppColors.wpaBlue,
      icon: Icon(
        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
      ),
      onPressed: onPressed,
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.speed, required this.onPressed});

  final double speed;
  final VoidCallback? onPressed;

  static String _label(double speed) {
    final text = speed == speed.roundToDouble()
        ? speed.toStringAsFixed(0)
        : speed.toString();
    return '${text}x';
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Semantics(
        label: 'Playback speed ${_label(speed)}',
        excludeSemantics: true,
        child: Text(_label(speed), style: context.text.labelLarge),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: context.text.bodySmall)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
