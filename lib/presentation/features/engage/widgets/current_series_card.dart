import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/engage/engage_home_cubit.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../design_system/components.dart';
import '../../../foundation/navigation/app_navigator.dart';

/// Current (active) series card, or a grey placeholder while loading.
class CurrentSeriesSection extends StatelessWidget {
  const CurrentSeriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngageHomeCubit, EngageHomeState>(
      builder: (context, state) {
        final series = state.currentSeries;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: series == null
              ? Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    color: AppColors.placeholderGrey,
                  ),
                )
              : CurrentSeriesCard(
                  series: series,
                  userProgress: state.seriesProgress.toDouble(),
                  expectedProgress: state.expectedSeriesProgress,
                ),
        );
      },
    );
  }
}

class CurrentSeriesCard extends StatelessWidget {
  const CurrentSeriesCard({
    super.key,
    required this.series,
    required this.userProgress,
    required this.expectedProgress,
  });

  final BibleSeries series;
  final double userProgress;
  final double expectedProgress;

  @override
  Widget build(BuildContext context) {
    final white70 = context.text.bodyMedium?.copyWith(color: Colors.white70);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        image: DecorationImage(
          image: CachedNetworkImageProvider(series.imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.5),
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Continue your journey with', style: white70),
          const SizedBox(height: 8),
          Text(
            series.title,
            style: context.text.headlineLarge?.copyWith(color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          _ProgressBar(user: userProgress, expected: expectedProgress),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => context.navigator.openBibleSeries(series.id),
              child: Text('Continue Reading', style: context.text.labelLarge),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: context.navigator.openAllBibleSeries,
              child: Text(
                'View Past Bible Series',
                style: white70?.copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.user, required this.expected});

  final double user;
  final double expected;

  Widget _bar(double fraction, Color color) => FractionallySizedBox(
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final small = context.text.bodySmall;
    return Column(
      children: [
        Stack(
          children: [
            _bar(1, Colors.white.withValues(alpha: 0.3)),
            _bar(expected / 100, Colors.white.withValues(alpha: 0.5)),
            _bar(user / 100, AppColors.wpaBlue),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${user.toInt()}% Complete',
                style: small?.copyWith(color: Colors.white)),
            Text('Target: ${expected.toInt()}%',
                style: small?.copyWith(color: Colors.white70)),
          ],
        ),
      ],
    );
  }
}
