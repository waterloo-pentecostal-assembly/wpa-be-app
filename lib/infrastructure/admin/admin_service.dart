import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/admin/interfaces.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/authentication/session.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/testimonies/entities.dart';
import '../../services/firebase_storage_service.dart';
import '../authentication/user_document.dart';
import '../common/firestore_data.dart';
import '../common/firestore_errors.dart';
import '../community_posts/firestore_post_store.dart';
import '../prayer_requests/prayer_requests_repository.dart';
import '../testimonies/testimonies_repository.dart';

class AdminService implements IAdminService {
  AdminService(
    this._firestore,
    this._storage,
    ISession session,
  )   : _prayerRequests = FirestorePostStore(
            _firestore, _storage, session, prayerRequestCollection),
        _testimonies = FirestorePostStore(
            _firestore, _storage, session, testimonyCollection);

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _storage;
  final FirestorePostStore<PrayerRequest> _prayerRequests;
  final FirestorePostStore<Testimony> _testimonies;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<List<LocalUser>> getUnverifiedUsers() async {
    final snapshot =
        await guardFirestore(_users.where('is_verified', isEqualTo: false).get);
    return parseAllSkippingInvalid(
        snapshot.docs, (doc) => parseUser(doc, _storage));
  }

  @override
  Future<void> verifyUser({required String userId}) =>
      guardFirestore(() => _users.doc(userId).update({'is_verified': true}));

  @override
  Future<void> deleteUnverifiedUsers({required String userId}) =>
      guardFirestore(() => _users.doc(userId).delete());

  @override
  Future<List<PrayerRequest>> getUnapprovedPrayerRequest() =>
      _prayerRequests.unapproved();

  @override
  Future<void> approvePrayerRequest({required String prayerRequestId}) =>
      _prayerRequests.approve(prayerRequestId);

  @override
  Future<void> deletePrayerRequest({required String prayerRequestId}) =>
      _prayerRequests.delete(prayerRequestId);

  @override
  Future<List<Testimony>> getUnapprovedTestimonies() =>
      _testimonies.unapproved();

  @override
  Future<void> approveTestimony({required String testimonyId}) =>
      _testimonies.approve(testimonyId);

  @override
  Future<void> deleteTestimony({required String testimonyId}) =>
      _testimonies.delete(testimonyId);
}
