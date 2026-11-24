import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/achievements/entities.dart';
import '../../domain/achievements/interfaces.dart';
import '../../domain/authentication/session.dart';
import '../common/firestore_data.dart';

class AchievementsRepository implements IAchievementsRepository {
  AchievementsRepository(this._firestore, this._session);

  final FirebaseFirestore _firestore;
  final ISession _session;

  /// `series_progress` is written by a Cloud Function; a missing document
  /// or field reads as 0.
  static Achievements _fromData(Map<String, dynamic>? data) => Achievements(
        seriesProgress: (data ?? const {}).optionalInt('series_progress'),
      );

  DocumentReference<Map<String, dynamic>> _doc([String? userId]) => _firestore
      .collection('achievements')
      .doc(userId ?? _session.requireUser().id);

  @override
  Future<Achievements> getAchievements() async {
    final doc = _doc();
    return _fromData((await doc.get()).data());
  }

  @override
  Stream<Achievements> watchAchievements() =>
      _doc().snapshots().map((s) => _fromData(s.data()));

  @override
  Stream<Achievements> watchUserAchievements(String userId) =>
      _doc(userId).snapshots().map((s) => _fromData(s.data()));
}
