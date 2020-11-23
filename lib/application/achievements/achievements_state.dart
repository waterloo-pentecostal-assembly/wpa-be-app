part of 'achievements_bloc.dart';

abstract class AchievementsState extends Equatable {
  const AchievementsState();

  @override
  List<Object> get props => [];
}

class AchievementsLoading extends AchievementsState {}

class AchievementsLoaded extends AchievementsState {
  final Achievements achievements;

  AchievementsLoaded({@required this.achievements});

  @override
  List<Object> get props => [achievements];
}

class AchievementsError extends AchievementsState {
  @override
  List<Object> get props => [];
}
