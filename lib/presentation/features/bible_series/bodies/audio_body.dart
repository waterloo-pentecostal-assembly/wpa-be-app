import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/audio_player/audio_player_cubit.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../design_system/tokens.dart';
import '../../../foundation/formatting/durations.dart';

/// Slider, elapsed/total time and play/pause for an audio body. The player is
/// app-scoped, so playback continues when leaving the page.
class AudioBodyView extends StatelessWidget {
  const AudioBodyView({super.key, required this.body, required this.contentId});

  final AudioBody body;
  final String contentId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AudioPlayerCubit>().state;
    final isCurrent = state.sourceUrl == body.audioFileUrl;
    final position = isCurrent ? state.position : Duration.zero;
    final duration = isCurrent ? state.duration : Duration.zero;
    final isPlaying = isCurrent && state.playerStatus == PlayerStatus.playing;
    final cubit = context.read<AudioPlayerCubit>();
    final max = duration.inSeconds.toDouble();

    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: 50, child: Text(formatMinutesSeconds(position))),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 10,
                  trackShape: const RoundedRectSliderTrackShape(),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14,
                    pressedElevation: 8,
                  ),
                  thumbColor: AppColors.wpaBlue,
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppColors.wpaBlue.withValues(alpha: 0.5),
                  inactiveTrackColor: AppColors.wpaBlue.withValues(alpha: 0.1),
                  disabledActiveTrackColor:
                      AppColors.wpaBlue.withValues(alpha: 0.5),
                  disabledInactiveTrackColor:
                      AppColors.wpaBlue.withValues(alpha: 0.1),
                  disabledThumbColor: AppColors.wpaBlue,
                ),
                child: Slider(
                  value: position.inSeconds.toDouble().clamp(0, max),
                  max: max,
                  onChanged: isCurrent
                      ? (v) => cubit.seek(Duration(seconds: v.toInt()))
                      : null,
                ),
              ),
            ),
            SizedBox(width: 50, child: Text(formatMinutesSeconds(duration))),
          ],
        ),
        const SizedBox(height: 12),
        IconButton(
          tooltip: isPlaying ? 'Pause' : 'Play',
          iconSize: 70,
          color: Colors.black87.withValues(alpha: 0.75),
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
          ),
          onPressed: () => isPlaying
              ? cubit.pause()
              : cubit.play(sourceUrl: body.audioFileUrl, contentId: contentId),
        ),
      ],
    );
  }
}
