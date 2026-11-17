import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/achievements/entities.dart';
import '../../domain/achievements/interfaces.dart';
import '../../domain/authentication/session.dart';
import '../../services/firebase_firestore_service.dart';
import '../common/helpers.dart';

class AchievementsRepository implements IAchievementsRepository {
  AchievementsRepository(
    this._firestore,
    this._firebaseFirestoreService,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final ISession _session;

  static Achievements _fromData(Map<String, dynamic>? data) => Achievements(
        seriesProgress: findOrDefaultTo(data ?? {}, 'series_progress', 0),
      );

  DocumentReference<Map<String, dynamic>> _doc() =>
      _firestore.collection('achievements').doc(_session.requireUser().id);

  @override
  Future<Achievements> getAchievements() async {
    try {
      final snapshot = await _doc().get();
      return _fromData(snapshot.data());
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Stream<Achievements> watchAchievements() =>
      _doc().snapshots().map((s) => _fromData(s.data())).handleError(
          (Object e) => throw _firebaseFirestoreService.handleException(e));
}
