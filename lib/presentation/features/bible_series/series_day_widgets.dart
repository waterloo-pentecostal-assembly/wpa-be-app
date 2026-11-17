import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/audio_player/audio_player_cubit.dart';
import '../../../domain/bible_series/entities.dart';
import '../../../domain/bible_series/progress.dart';
import '../../design_system/components.dart';
import '../../foundation/formatting/dates.dart';
import '../../foundation/navigation/app_navigator.dart';

/// One day of a series: today dot, month, day number, status icon.
class DayTab extends StatelessWidget {
  const DayTab({
    super.key,
    required this.day,
    required this.status,
    required this.isToday,
  });

  final SeriesContentSnippet day;
  final DayStatus status;
  final bool isToday;

  Color get _color => switch (status) {
        DayStatus.completed => AppColors.dayCompleted,
        DayStatus.late => AppColors.dayLate,
        DayStatus.neutral => AppColors.dayNeutral,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.md),
        color: _color,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Text(isToday ? '•' : ''),
            Text(DateFormats.monthAbbrev(day.date),
                style: context.text.labelLarge),
            const SizedBox(height: 3),
            Text(DateFormats.dayOfMonth(day.date),
                style: context.text.headlineLarge),
            const SizedBox(height: 3),
            CompletionStatusIcon(
              isCompleted: day.isCompleted,
              isDraft: day.isDraft,
            ),
          ],
        ),
      ),
    );
  }
}

class CompletionStatusIcon extends StatelessWidget {
  const CompletionStatusIcon({
    super.key,
    required this.isCompleted,
    required this.isDraft,
    this.size = 15,
  });

  final bool isCompleted;
  final bool isDraft;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) return Icon(Icons.done, size: size);
    if (isDraft) return Icon(Icons.edit, size: size);
    return const Text('');
  }
}

/// A content of a day (e.g. READ) with playing and completion indicators.
class ContentRow extends StatelessWidget {
  const ContentRow({super.key, required this.seriesId, required this.content});

  final String seriesId;
  final AvailableContentType content;

  @override
  Widget build(BuildContext context) {
    final isPlaying = context.select(
      (AudioPlayerCubit c) => c.state.isPlayingContent(content.contentId),
    );
    return GestureDetector(
      onTap: () => context.navigator.openContent(
        seriesId: seriesId,
        contentId: content.contentId,
        contentType: content.seriesContentType,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.textScalerOf(context).scale(AppSizes.contentRowHeight),
        ),
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          color: Colors.grey.shade100,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(content.seriesContentType,
                  style: context.text.titleLarge),
            ),
            if (isPlaying) const Icon(Icons.play_arrow_outlined),
            CompletionStatusIcon(
              isCompleted: content.isCompleted,
              isDraft: content.isDraft,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
