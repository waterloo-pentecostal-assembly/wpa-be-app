import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/bible_series/all_bible_series_cubit.dart';
import '../../../application/common/load_status.dart';
import '../../../domain/bible_series/entities.dart';
import '../../design_system/components.dart';
import '../../foundation/formatting/dates.dart';
import '../../foundation/layout/content_constraint.dart';
import '../../foundation/navigation/app_navigator.dart';

/// All Bible series. Expects an [AllBibleSeriesCubit] above it.
class AllBibleSeriesPage extends StatelessWidget {
  const AllBibleSeriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Bible Series'),
            Expanded(
              child: BlocBuilder<AllBibleSeriesCubit, AllBibleSeriesState>(
                builder: (context, state) {
                  if (state.status.isFailure) {
                    return ErrorState(state.errorMessage ?? '');
                  }
                  if (state.status.isLoading) return const LoadingState();
                  // A list, not a fixed-extent grid: cards grow with their
                  // text (subtitle lines, text scale).
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: state.series.length,
                    itemBuilder: (context, i) => ContentConstraint(
                      child: BibleSeriesListCard(series: state.series[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BibleSeriesListCard extends StatelessWidget {
  const BibleSeriesListCard({super.key, required this.series});

  final BibleSeries series;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.navigator.openBibleSeries(series.id),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        constraints: BoxConstraints(
          minHeight: MediaQuery.textScalerOf(context)
              .scale(AppSizes.seriesListCardHeight),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          // The text decides the card height (at least the minimum above);
          // the image fills the left third at whatever height that is.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageWidth = constraints.maxWidth / 3;
              return Stack(
                // Card width and minimum height reach the text column.
                fit: StackFit.passthrough,
                children: [
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    width: imageWidth,
                    child: AppNetworkImage(url: series.imageUrl),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: imageWidth),
                    child: _SeriesText(series: series),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SeriesText extends StatelessWidget {
  const _SeriesText({required this.series});

  final BibleSeries series;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(series.title, style: context.text.titleSmall),
          if (series.subTitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              series.subTitle,
              style: context.text.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            DateFormats.dateRange(series.startDate, series.endDate),
            style: context.text.labelSmall,
          ),
        ],
      ),
    );
  }
}
