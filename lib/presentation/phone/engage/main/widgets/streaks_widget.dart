import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../application/achievements/achievements_bloc.dart';

class StreaksWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AchievementsBloc, AchievementsState>(
      listener: (BuildContext context, state) {},
      builder: (BuildContext context, state) {
        if (state is AchievementsLoaded) {
          return Text(state.achievements.toString());
        } else if (state is AchievementsError) {
          return StreaksError(
            errorMessage: state.message,
          );
        }
        return StreaksTilePlaceholder();
      },
    );
  }
}

class StreaksTilePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Streaks Loading'),
    );
  }
}

class StreaksError extends StatelessWidget {
  final String errorMessage;

  const StreaksError({Key key, this.errorMessage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Streaks Error: $errorMessage'),
    );
  }
}
