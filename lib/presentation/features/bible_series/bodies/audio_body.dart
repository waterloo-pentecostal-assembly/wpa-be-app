import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/completions/content_detail_cubit.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../audio/audio_player_card.dart';

/// An audio body: the full player for its track. Expects a
/// [ContentDetailCubit] above it (it builds the track and its lock-screen
/// metadata).
class AudioBodyView extends StatelessWidget {
  const AudioBodyView({super.key, required this.body, required this.bodyIndex});

  final AudioBody body;
  final int bodyIndex;

  @override
  Widget build(BuildContext context) {
    final track = context
        .select((ContentDetailCubit c) => c.audioTrackFor(bodyIndex, body));
    return AudioPlayerCard(track: track);
  }
}
