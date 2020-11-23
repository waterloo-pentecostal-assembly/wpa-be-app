import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../../domain/achievements/entities.dart';
import '../../domain/achievements/interfaces.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../injection.dart';
import '../common/helpers.dart';
import 'achievements_dto.dart';

class AchievementsRepository implements IAchievementsRepository {
  final FirebaseFirestore _firestore;
  CollectionReference _achievementsCollection;

  AchievementsRepository(this._firestore) {
    _achievementsCollection = _firestore.collection("achievements");
  }

  @override
  Future<Achievements> getAchievements() async {
    DocumentSnapshot documentSnapshot;
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    try {
      documentSnapshot = await _achievementsCollection.doc(user.id).get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }

    if (documentSnapshot.data().isEmpty) {
      return Achievements(currentStreak: 0, longestStreak: 0, perfectSeries: 0);
    }

    return AchievementsDto.fromFirestore(documentSnapshot).toDomain();
  }

  @override
  Stream<Achievements> watchAchievements() async* {
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    try {
      yield* _achievementsCollection.doc(user.id).snapshots().map((documentSnapshot) {
        if (documentSnapshot.data() == null) {
          return Achievements(currentStreak: 0, longestStreak: 0, perfectSeries: 0);
        }
        return AchievementsDto.fromFirestore(documentSnapshot).toDomain();
      });
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }
  }
}
