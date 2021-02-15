import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/achievements/entities.dart';
import '../../domain/achievements/interfaces.dart';
import '../../domain/authentication/entities.dart';
import '../../app/injection.dart';
import '../../services/firebase_firestore_service.dart';
import 'achievements_dto.dart';

class AchievementsRepository implements IAchievementsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;
  CollectionReference _achievementsCollection;

  AchievementsRepository(this._firestore, this._firebaseFirestoreService) {
    _achievementsCollection = _firestore.collection("achievements");
  }

  @override
  Future<Achievements> getAchievements() async {
    DocumentSnapshot documentSnapshot;
    final LocalUser user = getIt<LocalUser>();
    try {
      documentSnapshot = await _achievementsCollection.doc(user.id).get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    if (documentSnapshot.data().isEmpty) {
      return Achievements(seriesProgress: 0);
    }

    return AchievementsDto.fromFirestore(documentSnapshot).toDomain();
  }

  @override
  Stream<Achievements> watchAchievements() async* {
    final LocalUser user = getIt<LocalUser>();
    try {
      yield* _achievementsCollection
          .doc(user.id)
          .snapshots()
          .map((documentSnapshot) {
        if (documentSnapshot.data() == null) {
          return Achievements(seriesProgress: 0);
        }
        return AchievementsDto.fromFirestore(documentSnapshot).toDomain();
      });
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }
}
