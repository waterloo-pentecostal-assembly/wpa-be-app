import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../application/achievements/achievements_bloc.dart';
import '../../../../../domain/achievements/entities.dart';
import '../../../../../injection.dart';
import '../../../../common/loader.dart';
import '../../../common/text_factory.dart';

class StreaksWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AchievementsBloc, AchievementsState>(
      listener: (BuildContext context, state) {},
      builder: (BuildContext context, state) {
        return Container(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          child: getChild(state),
        );
      },
    );
  }

  Widget getChild(AchievementsState state) {
    if (state is AchievementsLoaded) {
      return StreaksTile(
        achievements: state.achievements,
      );
    } else if (state is AchievementsError) {
      return StreaksError();
    }
    return StreaksTilePlaceholder();
  }
}

class StreaksTile extends StatelessWidget {
  final Achievements achievements;

  const StreaksTile({Key key, @required this.achievements}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                getIt<TextFactory>().subHeading3('CURRENT STREAK'),
                Row(
                  children: [
                    getIt<TextFactory>().heading('${achievements.currentStreak}', fontWeight: FontWeight.w500),
                    Icon(Icons.flash_on, color: Colors.grey.shade600)
                  ],
                ),
                getIt<TextFactory>().lite('BEST: ${achievements.longestStreak} DAY${getS(achievements.longestStreak)}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
            child: VerticalDivider(),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                getIt<TextFactory>().subHeading3('PERFECT SERIES'),
                Row(
                  children: [
                    getIt<TextFactory>().heading('${achievements.perfectSeries}', fontWeight: FontWeight.w500),
                    Icon(
                      Icons.star,
                      color: Colors.grey.shade600,
                    )
                  ],
                ),
                getIt<TextFactory>().lite('ALL TIME'),
              ],
            ),
          )
        ],
      ),
    );
  }

  String getS(int value) {
    if (value == 1) {
      return '';
    }
    return 'S';
  }
}

class StreaksTilePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        alignment: Alignment.center,
        child: Loader(),
      ),
    );
  }
}

class StreaksError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        alignment: Alignment.center,
        child: Text('Unable to load streaks'),
      ),
    );
  }
}
