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

class WatchAchievementsStarted extends AchievementsEvent {
  @override
  List<Object> get props => [];
}

class AchievementsReceived extends AchievementsEvent {
  final Achievements achievements;

  AchievementsReceived({required this.achievements});

  @override
  List<Object> get props => [achievements];
}

class AchievementsErrorReceived extends AchievementsEvent {
  @override
  List<Object> get props => [];
}
