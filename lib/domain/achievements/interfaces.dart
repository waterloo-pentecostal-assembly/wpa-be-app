import 'entities.dart';

abstract class IAchievementsRepository {
  Future<Achievements> getAchievements();
  Stream<Achievements> watchAchievements();
}
