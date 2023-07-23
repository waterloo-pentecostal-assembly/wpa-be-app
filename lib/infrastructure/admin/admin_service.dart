import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/domain/admin/interfaces.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/prayer_requests/entities.dart';
import 'package:wpa_app/infrastructure/authentication/firebase_user_dto.dart';
import 'package:wpa_app/infrastructure/prayer_requests/prayer_requests_dto.dart';
import 'package:wpa_app/services/firebase_firestore_service.dart';
import 'package:wpa_app/services/firebase_storage_service.dart';

class AdminService implements IAdminService {
  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;
  final FirebaseFirestoreService _firebaseFirestoreService;

  AdminService(this._firestore, this._firebaseFirestoreService, this._firebaseStorageService);

  @override
  Future<List<LocalUser>> getUnverifiedUsers() async {
    late QuerySnapshot<Map<String, dynamic>> querySnapshot;
    List<LocalUser> localUsers = [];
    try {
      querySnapshot = await _firestore
          .collection('users')
          .where("is_verified", isEqualTo: false)
          .get();
    } on Exception catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    for (QueryDocumentSnapshot<Map<String, dynamic>> doc in querySnapshot.docs) {
      LocalUser localUser = await FirebaseUserDto.fromFirestore(doc).toDomain(_firebaseStorageService);
      localUsers.add(localUser);
    }

    return localUsers;
  }

  @override
  Future<void> verifyUser({required String userId}) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference = _firestore.collection("users").doc(userId);
        transaction.update(documentReference, {'is_verified': true});
      });
    } on Exception catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> approvePrayerRequest({required String prayerRequestId}) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference = _firestore.collection("prayer_requests").doc(prayerRequestId);
        transaction.update(documentReference, {"is_approved": true});
      });
    } on Exception catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<List<PrayerRequest>> getUnapprovedPrayerRequest() async {
    final LocalUser user = getIt<LocalUser>();
    late QuerySnapshot<Map<String, dynamic>> querySnapshot;
    List<PrayerRequest> prayerRequests = [];
    try {
      querySnapshot = await _firestore.collection("prayer_requests").where("is_approved", isEqualTo: false).get();
    } on Exception catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    for (QueryDocumentSnapshot<Map<String, dynamic>> doc in querySnapshot.docs) {
      PrayerRequest prayerRequest =
          await PrayerRequestsDto.fromFirestore(doc, user.id).toDomain(_firebaseStorageService);
      prayerRequests.add(prayerRequest);
    }

    return prayerRequests;
  }

  @override
  Future<void> deletePrayerRequest({required String prayerRequestId}) async {
    try {
      await _firestore.collection("prayer_requests").doc(prayerRequestId).delete();
    } on Exception catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> deleteUnverifiedUsers({required String userId}) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } on Exception catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }
}
