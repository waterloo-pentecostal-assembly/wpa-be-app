import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/common/load_status.dart';
import '../../../../application/engage/engage_home_cubit.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../design_system/components.dart';
import '../../../foundation/formatting/dates.dart';
import '../../../foundation/navigation/app_navigator.dart';

/// "Past Bible Series" horizontal carousel (no active series).
class PastSeriesSection extends StatelessWidget {
  const PastSeriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final height = AppSizes.pastSeriesTileHeight +
        MediaQuery.textScalerOf(context)
            .scale(AppSizes.pastSeriesTileDescriptionHeight);
    return Column(
      children: [
        SectionHeader(
          title: 'Past Bible Series',
          trailing: GestureDetector(
            onTap: context.navigator.openAllBibleSeries,
            child: Text('Show all', style: context.text.labelLarge),
          ),
        ),
        BlocBuilder<EngageHomeCubit, EngageHomeState>(
          builder: (context, state) {
            final loaded = state.seriesStatus == LoadStatus.success;
            return SizedBox(
              height: height,
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 16),
                scrollDirection: Axis.horizontal,
                itemCount: loaded ? state.series.length : 3,
                itemBuilder: (context, i) => loaded
                    ? PastSeriesTile(series: state.series[i])
                    : const Padding(
                        padding: EdgeInsets.all(8),
                        child: PlaceholderBox(
                          width: AppSizes.pastSeriesTileWidth,
                          height: AppSizes.pastSeriesTileHeight,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class PastSeriesTile extends StatelessWidget {
  const PastSeriesTile({super.key, required this.series});

  final BibleSeries series;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.navigator.openBibleSeries(series.id),
      child: Container(
        width: AppSizes.pastSeriesTileWidth,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: AppNetworkImage(
                url: series.imageUrl,
                height: AppSizes.pastSeriesTileHeight,
                width: double.infinity,
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Text(series.title, style: context.text.labelLarge),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                DateFormats.dateRange(series.startDate, series.endDate),
                style: context.text.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
