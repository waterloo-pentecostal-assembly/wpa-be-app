import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/achievements/entities.dart';
import '../../domain/achievements/interfaces.dart';
import '../../domain/authentication/entities.dart';
import '../../app/injection.dart';
import '../../services/firebase_firestore_service.dart';

class AchievementsRepository implements IAchievementsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;
  late CollectionReference _achievementsCollection;

  AchievementsRepository(this._firestore, this._firebaseFirestoreService) {
    _achievementsCollection = _firestore.collection("achievements");
  }

  @override
  Future<Achievements> getAchievements() async {
    late DocumentSnapshot<Achievements> documentSnapshot;
    final LocalUser user = getIt<LocalUser>();
    try {
      documentSnapshot = await _achievementsCollection
          .doc(user.id)
          .withConverter<Achievements>(
              fromFirestore: (snapshots, _) =>
                  Achievements.fromJson(snapshots.data()!),
              toFirestore: (model, _) => model.toJson())
          .get();
    } on Exception catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
    return documentSnapshot.data() ?? Achievements(seriesProgress: 0);
  }

  @override
  Stream<Achievements> watchAchievements() async* {
    final LocalUser user = getIt<LocalUser>();
    try {
      yield* _achievementsCollection
          .doc(user.id)
          .withConverter<Achievements>(
              fromFirestore: (snapshots, _) =>
                  Achievements.fromJson(snapshots.data()!),
              toFirestore: (model, _) => model.toJson())
          .snapshots()
          .map((documentSnapshot) {
            return documentSnapshot.data() ?? Achievements(seriesProgress: 0);
          });
    } on Exception catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }
}
