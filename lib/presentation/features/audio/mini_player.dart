import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/audio_player/audio_player_cubit.dart';
import '../../../domain/audio/entities.dart';
import '../../design_system/components.dart';
import '../../foundation/navigation/app_navigator.dart';
import 'audio_player_card.dart';

/// Compact player shown at the bottom of the main shell while a track is
/// loaded: progress, artwork, title, play/pause and close (stops playback).
/// Tapping it opens the content the track was started from.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final track = context.select((AudioPlayerCubit c) => c.state.track);
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: track == null
          ? const SizedBox(width: double.infinity)
          : _MiniPlayerBar(track: track),
    );
  }
}

class _MiniPlayerBar extends StatelessWidget {
  const _MiniPlayerBar({required this.track});

  final AudioTrack track;

  void _open(BuildContext context) {
    final origin = track.origin;
    if (origin == null) return;
    context.navigator.openContent(
      seriesId: origin.seriesId,
      contentId: origin.contentId,
      contentType: origin.contentType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AudioPlayerCubit>();
    final state = context.watch<AudioPlayerCubit>().state;
    final duration = state.duration.inMilliseconds;
    final progress =
        duration > 0 ? state.position.inMilliseconds / duration : 0.0;
    final artwork = track.artworkUrl;
    final subtitle = track.subtitle;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: track.origin == null ? null : () => _open(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 2,
                color: AppColors.wpaBlue,
                backgroundColor: AppColors.wpaBlue.withValues(alpha: 0.12),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: artwork == null
                          ? Container(
                              width: 40,
                              height: 40,
                              color: AppColors.placeholderGrey,
                              child: const Icon(Icons.headphones, size: 20),
                            )
                          : AppNetworkImage(
                              url: artwork, width: 40, height: 40),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Semantics(
                        label: 'Now playing',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              track.title,
                              style: context.text.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                style: context.text.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                    PlayPauseButton(
                      isPlaying: state.isPlaying,
                      isLoading: state.isLoading,
                      size: 40,
                      onPressed: () => cubit.toggle(track),
                    ),
                    IconButton(
                      tooltip: 'Stop',
                      icon: const Icon(Icons.close),
                      onPressed: cubit.stop,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
