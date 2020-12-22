import 'entities.dart';

abstract class IAchievementsRepository {
  /// Get all acheivements for signed in user. Returns an [Achievements] object
  Future<Achievements> getAchievements();

  Stream<Achievements> watchAchievements();
}
