import 'entities.dart';

abstract class IAchievementsRepository {
  Future<Achievements> getAchievements();
  Stream<Achievements> watchAchievements();

  /// Another user's achievements, live (e.g. a challenge group member's).
  Stream<Achievements> watchUserAchievements(String userId);
}
