import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/bible_series/bible_series_detail_cubit.dart';
import '../../../application/common/load_status.dart';
import '../../design_system/components.dart';
import '../../foundation/layout/content_constraint.dart';
import '../../foundation/navigation/app_navigator.dart';
import 'series_day_widgets.dart';

/// Series detail: hero image, "Discussion" button, day tabs and the contents
/// of each day. Expects a [BibleSeriesDetailCubit] above it.
class BibleSeriesDetailPage extends StatelessWidget {
  const BibleSeriesDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BibleSeriesDetailCubit, BibleSeriesDetailState>(
      buildWhen: (a, b) => a.status != b.status,
      builder: (context, state) {
        if (state.status.isFailure) {
          return Scaffold(
            body: SafeArea(child: Text('Error: ${state.errorMessage}')),
          );
        }
        if (state.status.isLoading) return const _DetailPlaceholder();
        return DefaultTabController(
          length: state.series!.seriesContentSnippet.length,
          initialIndex: state.initialDayIndex,
          child: const Scaffold(
            body: Column(
              children: [
                _Hero(),
                _DayTabs(),
                Expanded(child: _DayContents()),
              ],
            ),
          ),
        );
      },
    );
  }
}

double _heroHeight(BuildContext context) =>
    0.35 * MediaQuery.sizeOf(context).height;

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final series = context.select(
      (BibleSeriesDetailCubit c) => c.state.series!,
    );
    return Stack(
      children: [
        Container(
          height: _heroHeight(context),
          width: double.infinity,
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppSpacing.xxl),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(url: series.imageUrl),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.4],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.heading),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back, size: AppSizes.icon),
                  color: Colors.white,
                  onPressed: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  // The series id is the forum id.
                  onPressed: () => context.navigator.openForum(series.id),
                  child: Text('Discussion', style: context.text.labelLarge),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DayTabs extends StatelessWidget {
  const _DayTabs();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<BibleSeriesDetailCubit>();
    final days = cubit.state.series!.seriesContentSnippet;
    final height =
        MediaQuery.textScalerOf(context).scale(AppSizes.dayTabHeight);
    return TabBar(
      labelPadding: const EdgeInsets.all(8),
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicator: const BoxDecoration(color: Colors.transparent),
      dividerColor: Colors.transparent,
      labelColor: Colors.black87,
      unselectedLabelColor: Colors.black45,
      tabs: [
        for (final day in days)
          SizedBox(
            height: height,
            width: AppSizes.dayTabWidth,
            child: DayTab(
              day: day,
              status: cubit.dayStatus(day),
              isToday: cubit.isToday(day),
            ),
          ),
      ],
    );
  }
}

class _DayContents extends StatelessWidget {
  const _DayContents();

  @override
  Widget build(BuildContext context) {
    final series = context.select(
      (BibleSeriesDetailCubit c) => c.state.series!,
    );
    return TabBarView(
      children: [
        for (final day in series.seriesContentSnippet)
          ListView(
            padding: const EdgeInsets.only(top: 20),
            children: [
              for (final content in day.availableContentTypes)
                ContentConstraint(
                  child: ContentRow(seriesId: series.id, content: content),
                ),
            ],
          ),
      ],
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              PlaceholderBox(
                height: _heroHeight(context),
                width: double.infinity,
                radius: AppSpacing.xxl,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.heading),
                  child: IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back, size: AppSizes.icon),
                    color: Colors.white,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 148,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(26, 10, 10, 10),
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.all(8),
                child: PlaceholderBox(
                  width: AppSizes.dayTabWidth,
                  height: AppSizes.dayTabHeight,
                  radius: AppRadii.md,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
