import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/admin/interfaces.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/authentication/session.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/testimonies/entities.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import '../authentication/firebase_user_dto.dart';
import '../prayer_requests/prayer_requests_dto.dart';
import '../testimonies/testimonies_dto.dart';

class AdminService implements IAdminService {
  AdminService(
    this._firestore,
    this._firebaseFirestoreService,
    this._firebaseStorageService,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final FirebaseStorageService _firebaseStorageService;
  final ISession _session;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  Future<void> _setFlag(String collection, String id, String field) =>
      _guard(() => _firestore.runTransaction((transaction) async {
            transaction.update(
              _firestore.collection(collection).doc(id),
              {field: true},
            );
          }));

  @override
  Future<List<LocalUser>> getUnverifiedUsers() async {
    final snapshot = await _guard(() => _firestore
        .collection('users')
        .where('is_verified', isEqualTo: false)
        .get());
    return Future.wait(snapshot.docs.map(
      (doc) =>
          FirebaseUserDto.fromFirestore(doc).toDomain(_firebaseStorageService),
    ));
  }

  @override
  Future<void> verifyUser({required String userId}) =>
      _setFlag('users', userId, 'is_verified');

  @override
  Future<void> deleteUnverifiedUsers({required String userId}) =>
      _guard(() => _firestore.collection('users').doc(userId).delete());

  @override
  Future<void> approvePrayerRequest({required String prayerRequestId}) =>
      _setFlag('prayer_requests', prayerRequestId, 'is_approved');

  @override
  Future<List<PrayerRequest>> getUnapprovedPrayerRequest() async {
    final user = _session.requireUser();
    final snapshot = await _guard(() => _firestore
        .collection('prayer_requests')
        .where('is_approved', isEqualTo: false)
        .get());
    return Future.wait(snapshot.docs.map((doc) =>
        PrayerRequestsDto.fromFirestore(
            doc, user.id, _firebaseStorageService)));
  }

  @override
  Future<void> deletePrayerRequest({required String prayerRequestId}) =>
      _guard(() => _firestore
          .collection('prayer_requests')
          .doc(prayerRequestId)
          .delete());

  @override
  Future<void> approveTestimony({required String testimonyId}) =>
      _setFlag('testimonies', testimonyId, 'is_approved');

  @override
  Future<List<Testimony>> getUnapprovedTestimonies() async {
    final user = _session.requireUser();
    final snapshot = await _guard(() => _firestore
        .collection('testimonies')
        .where('is_approved', isEqualTo: false)
        .get());
    return Future.wait(snapshot.docs.map((doc) =>
        TestimoniesDto.fromFirestore(doc, user.id, _firebaseStorageService)));
  }

  @override
  Future<void> deleteTestimony({required String testimonyId}) => _guard(
      () => _firestore.collection('testimonies').doc(testimonyId).delete());
}
