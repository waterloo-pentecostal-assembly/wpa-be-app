import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/common/load_status.dart';
import '../../../application/engage/engage_home_cubit.dart';
import '../../design_system/components.dart';
import 'widgets/community_shortcuts.dart';
import 'widgets/current_series_card.dart';
import 'widgets/media_carousel.dart';
import 'widgets/past_series_carousel.dart';

/// Engage tab root. Expects an [EngageHomeCubit] above it.
class EngageHomePage extends StatelessWidget {
  const EngageHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<EngageHomeCubit, EngageHomeState>(
          buildWhen: (a, b) =>
              a.status != b.status ||
              a.hasActiveSeries != b.hasActiveSeries ||
              a.firstName != b.firstName,
          builder: (context, state) {
            if (state.status.isLoading) return const LoadingState();
            return RefreshIndicator(
              onRefresh: context.read<EngageHomeCubit>().refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 16),
                  PageHeading(
                    'Hello, ${state.firstName}!',
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                  ),
                  if (state.hasActiveSeries)
                    const CurrentSeriesSection()
                  else
                    const PastSeriesSection(),
                  const SizedBox(height: 16),
                  const CommunityShortcuts.prayerRequests(),
                  const CommunityShortcuts.testimonies(),
                  const SizedBox(height: 16),
                  const MediaSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
