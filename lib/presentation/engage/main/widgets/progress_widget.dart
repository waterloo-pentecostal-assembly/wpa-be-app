import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:wpa_app/application/bible_series/bible_series_bloc.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';

import '../../../../app/constants.dart';
import '../../../../app/injection.dart';
import '../../../../application/achievements/achievements_bloc.dart';
import '../../../../domain/achievements/entities.dart';
import '../../../common/loader.dart';
import '../../../common/text_factory.dart';

class ProgressWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AchievementsBloc, AchievementsState>(
      listener: (BuildContext context, state) {},
      builder: (BuildContext context, state) {
        return Container(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          child: getChild(state),
        );
      },
    );
  }

  Widget getChild(AchievementsState state) {
    if (state is AchievementsLoaded) {
      return ProgressTile(
        achievements: state.achievements,
      );
    } else if (state is AchievementsError) {
      return ProgressError();
    }
    return ProgressTilePlaceholder();
  }
}

class ProgressTile extends StatelessWidget {
  final Achievements achievements;

  const ProgressTile({Key key, @required this.achievements}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              height: kProgressWidgetWidth,
              child: SfRadialGauge(
                enableLoadingAnimation: true,
                axes: [
                  RadialAxis(
                    showLabels: false,
                    showTicks: false,
                    startAngle: 180,
                    endAngle: 0,
                    radiusFactor: 1,
                    canScaleToFit: true,
                    axisLineStyle: AxisLineStyle(
                      thickness: 0.2,
                      color: kWpaBlue.withOpacity(0.15),
                      thicknessUnit: GaugeSizeUnit.factor,
                      // cornerStyle: CornerStyle.bothCurve,
                      // remove bothCurve because of this bug
                      // https://github.com/syncfusion/flutter-widgets/issues/99
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        color: kWpaBlue.withOpacity(0.5),
                        value: achievements.seriesProgress.toDouble(),
                        width: 0.2,
                        sizeUnit: GaugeSizeUnit.factor,
                        // cornerStyle: CornerStyle.bothCurve,
                      ),
                      getExpectedIndicator(state)
                    ],
                    annotations: [
                      GaugeAnnotation(
                        positionFactor: 0.1,
                        angle: 270,
                        widget: Column(
                          children: [
                            SizedBox(
                              height: 0.2 * kProgressWidgetWidth,
                            ),
                            Container(
                                child: getIt<TextFactory>().subHeading(
                                    '${achievements.seriesProgress}%')),
                            Container(
                                child: getIt<TextFactory>().regular(
                                    '${getProgressBarPhrase(achievements.seriesProgress)}')),
                            SizedBox(
                              height: 10,
                            ),
                            ProgressWidgetTitle()
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String getProgressBarPhrase(progress) {
    if (progress == 0) {
      return "Let's go!";
    } else if (progress < 20) {
      return "Great start!";
    } else if (progress < 60) {
      return "Keep it up!";
    } else if (progress < 90) {
      return "Almost there!";
    } else if (progress < 99) {
      return "So close!";
    } else {
      return "You did it!";
    }
  }

  GaugePointer getExpectedIndicator(BibleSeriesState state) {
    double seriesValue = 0;
    if (state is RecentBibleSeries) {
      seriesValue = getExpectedProgress(state.bibleSeriesList);
    }
    return MarkerPointer(
        value: seriesValue,
        enableDragging: false,
        enableAnimation: true,
        markerHeight: 15,
        markerOffset: -20,
        color: Colors.black);
  }
}

class ProgressTilePlaceholder extends StatelessWidget {
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

class ProgressError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        alignment: Alignment.center,
        child: Text('Unable to load Progress'),
      ),
    );
  }
}

class ProgressWidgetTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is RecentBibleSeries) {
          return Center(
            child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                    style: getIt<TextFactory>().liteTextStyle(),
                    children: [
                      TextSpan(text: "Your Progress for "),
                      TextSpan(
                          text: getLastestActive(state.bibleSeriesList),
                          style: getIt<TextFactory>().regularTextStyle())
                    ])),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

String getLastestActive(List<BibleSeries> bibleSeriesList) {
  for (int i = 0; i < bibleSeriesList.length; i++) {
    if (bibleSeriesList[i].isActive) {
      return bibleSeriesList[i].title;
    }
  }
  return '';
}

double getExpectedProgress(List<BibleSeries> bibleSeriesList) {
  for (int i = 0; i < bibleSeriesList.length; i++) {
    if (bibleSeriesList[i].isActive) {
      int totalDays = 0;
      int finishedDays = 0;
      bibleSeriesList[i].seriesContentSnippet.forEach((element) {
        if (!element.date.toDate().isAfter(DateTime.now())) {
          finishedDays++;
        }
        totalDays++;
      });
      return (finishedDays / totalDays * 100);
    }
  }
  return 0;
}
