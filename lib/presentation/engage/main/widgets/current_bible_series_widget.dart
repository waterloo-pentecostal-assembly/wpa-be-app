import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/achievements/achievements_bloc.dart';
import 'package:wpa_app/app/constants.dart';
import '../../../../app/injection.dart';
import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../common/text_factory.dart';

class CurrentBibleSeriesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
      listener: (BuildContext context, BibleSeriesState state) {},
      builder: (BuildContext context, BibleSeriesState state) {
        if (state is RecentBibleSeries && state.bibleSeriesList.isNotEmpty) {
          // Find the first active series, or default to the first one if all are inactive (though logic says isActive=true in request)
          BibleSeries activeSeries = state.bibleSeriesList.first;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ActiveBibleSeriesCard(bibleSeries: activeSeries),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade200,
              ),
            ),
          );
        }
      },
    );
  }
}

class ActiveBibleSeriesCard extends StatelessWidget {
  final BibleSeries bibleSeries;

  const ActiveBibleSeriesCard({Key? key, required this.bibleSeries})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AchievementsBloc, AchievementsState>(
      builder: (context, state) {
        double userProgress = 0;
        if (state is AchievementsLoaded) {
          userProgress = state.achievements.seriesProgress.toDouble();
        }

        double expectedProgress = getExpectedProgress(bibleSeries);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: CachedNetworkImageProvider(bibleSeries.imageUrl),
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
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getIt<TextFactory>().lite(
                  'Continue your journey with',
                  color: Colors.white70,
                  fontSize: 14.0,
                ),
                SizedBox(height: 8),
                Text(
                  bibleSeries.title,
                  style: getIt<TextFactory>()
                      .regularTextStyle(color: Colors.white, fontSize: 30.0)
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 24),
                _buildProgressBar(userProgress, expectedProgress),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/bible_series',
                          arguments: {'bibleSeriesId': bibleSeries.id});
                    },
                    child: getIt<TextFactory>().regular('Continue Reading'),
                  ),
                ),
                SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/all_bible_series'),
                    child: Text(
                      'View Past Bible Series',
                      style: getIt<TextFactory>()
                          .liteTextStyle(color: Colors.white70)
                          .copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(double userProgress, double expectedProgress) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Expected Progress
            FractionallySizedBox(
              widthFactor: (expectedProgress / 100).clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // User Progress
            FractionallySizedBox(
              widthFactor: (userProgress / 100).clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: kWpaBlue, // Use app theme color or specific green/blue
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            getIt<TextFactory>().lite(
              '${userProgress.toInt()}% Complete',
              color: Colors.white,
              fontSize: 12.0,
            ),
            getIt<TextFactory>().lite(
              'Target: ${expectedProgress.toInt()}%',
              color: Colors.white70,
              fontSize: 12.0,
            ),
          ],
        ),
      ],
    );
  }

  double getExpectedProgress(BibleSeries bibleSeries) {
    int totalDays = 0;
    int finishedDays = 0;
    bibleSeries.seriesContentSnippet.forEach((element) {
      if (!element.date.toDate().isAfter(DateTime.now())) {
        finishedDays++;
      }
      totalDays++;
    });
    if (totalDays == 0) return 0;
    return (finishedDays / totalDays * 100);
  }
}
