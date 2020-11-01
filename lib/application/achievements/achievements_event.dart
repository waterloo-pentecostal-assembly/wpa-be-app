part of 'achievements_bloc.dart';

abstract class AchievementsEvent extends Equatable {
  const AchievementsEvent();

  @override
  List<Object> get props => [];
}

class AchievementsRequested extends AchievementsEvent {
  @override
  List<Object> get props => [];
}
