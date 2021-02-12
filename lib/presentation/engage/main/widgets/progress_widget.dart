import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

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
          decoration: BoxDecoration(color: Colors.grey.shade200),
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
    return Column(
      children: [
        Container(
          height: kProgressWidgeetWidth,
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
                  cornerStyle: CornerStyle.bothCurve,
                ),
                pointers: <GaugePointer>[
                  RangePointer(
                    color: kWpaBlue.withOpacity(0.5),
                    value: achievements.seriesProgress.toDouble(),
                    width: 0.2,
                    sizeUnit: GaugeSizeUnit.factor,
                    cornerStyle: CornerStyle.bothCurve,
                  )
                ],
                annotations: [
                  GaugeAnnotation(
                    positionFactor: 0.1,
                    angle: 270,
                    widget: Column(
                      children: [
                        SizedBox(
                          height: 0.2 * kProgressWidgeetWidth,
                        ),
                        Container(
                            child: getIt<TextFactory>()
                                .subHeading('${achievements.seriesProgress}%')),
                        Container(
                            child: getIt<TextFactory>().regular(
                                '${getProgressBarPhrase(achievements.seriesProgress)}')),
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
