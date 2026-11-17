import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/common/paging.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/prayer_requests/exceptions.dart';
import '../../domain/prayer_requests/interfaces.dart';
import '../../domain/prayer_requests/rules.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import '../common/firestore_page_cursor.dart';
import '../common/helpers.dart';
import '../common/user_snippet_dto.dart';
import 'prayer_requests_dto.dart';

class PrayerRequestsRepository implements IPrayerRequestsRepository {
  PrayerRequestsRepository(
    this._firestore,
    this._firebaseStorageService,
    this._firebaseFirestoreService,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final ISession _session;

  CollectionReference get _collection =>
      _firestore.collection('prayer_requests');

  Future<List<PrayerRequest>> _toDomain(
          List<DocumentSnapshot> docs, String userId) =>
      Future.wait(docs.map(
        (doc) => PrayerRequestsDto.fromFirestore(
            doc, userId, _firebaseStorageService),
      ));

  Future<QuerySnapshot> _get(Query query) async {
    try {
      return await query.get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<PrayerRequest> createPrayerRequest({
    required String request,
    required bool isAnonymous,
  }) async {
    final user = _session.requireUser();
    final DocumentSnapshot snapshot;
    try {
      final ref = await _collection.add(PrayerRequestsDto.newDocument(
        request: request,
        isAnonymous: isAnonymous,
        userId: user.id,
        userSnippet: UserSnippetDto.fromDomain(user),
        date: Timestamp.now(),
      ));
      snapshot = await ref.get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    return PrayerRequestsDto.fromFirestore(
        snapshot, user.id, _firebaseStorageService);
  }

  @override
  Future<void> deletePrayerRequest({required String id}) async {
    try {
      await _collection.doc(id).delete();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  Future<List<PrayerRequest>> _mine({required bool closed}) async {
    final user = _session.requireUser();
    final snapshot = await _get(_collection
        .where('user_id', isEqualTo: user.id)
        .where('is_answered', isEqualTo: closed)
        .orderBy('date', descending: true));
    return _toDomain(snapshot.docs, user.id);
  }

  @override
  Future<List<PrayerRequest>> getMyPrayerRequests() => _mine(closed: false);

  @override
  Future<List<PrayerRequest>> getMyAnsweredPrayerRequests() =>
      _mine(closed: true);

  @override
  Future<PrayerRequest> closePrayerRequest({required String id}) async {
    final user = _session.requireUser();
    final DocumentSnapshot snapshot;
    try {
      final ref = _collection.doc(id);
      await ref.update({'is_answered': true});
      snapshot = await ref.get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    return PrayerRequestsDto.fromFirestore(
        snapshot, user.id, _firebaseStorageService);
  }

  @override
  Future<PageResult<PrayerRequest>> getPrayerRequests({
    required int limit,
    PageCursor? after,
  }) async {
    final user = _session.requireUser();
    final snapshot = await _get(_collection
        .where('is_approved', isEqualTo: true)
        .where('is_answered', isEqualTo: false)
        .orderBy('date', descending: true)
        .page(limit: limit, after: after));
    return PageResult(
      items: await _toDomain(snapshot.docs, user.id),
      nextCursor: nextCursorFor(snapshot, limit),
    );
  }

  @override
  Future<void> prayForPrayerRequest({required String id}) async {
    final user = _session.requireUser();
    try {
      // Transaction to avoid stale data.
      await _firestore.runTransaction((transaction) async {
        final ref = _collection.doc(id);
        final snapshot = await transaction.get(ref);
        if (snapshot.data() == null) {
          throw const PrayerRequestsException(
            code: PrayerRequestsExceptionCode.prayerRequestNotFound,
            message: 'Prayer request not found',
          );
        }
        final List<dynamic> reactedBy = findOrDefaultTo(
          snapshot.data() as Map<String, dynamic>,
          'prayed_by',
          [],
        );
        transaction.update(ref, {
          'prayed_by': [...reactedBy, user.id]
        });
      });
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> reportPrayerRequest({required String id}) async {
    final user = _session.requireUser();
    try {
      await _firestore.runTransaction((transaction) async {
        final ref = _collection.doc(id);
        final snapshot = await transaction.get(ref);
        final data = (snapshot.data() ?? {}) as Map<String, dynamic>;
        final List<dynamic> reportedBy = data['reported_by'] ?? [];
        if (reportedBy.contains(user.id)) {
          throw const PrayerRequestsException(
            code: PrayerRequestsExceptionCode.alreadyReported,
            message: 'You already reported this prayer request',
          );
        }
        transaction.update(ref, {
          'reported_by': [...reportedBy, user.id],
          'is_approved': false,
        });
      });
    } on PrayerRequestsException {
      rethrow;
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<bool> canAddPrayerRequest() async {
    final user = _session.requireUser();
    final snapshot = await _get(_collection
        .where('user_id', isEqualTo: user.id)
        .where('is_approved', isEqualTo: true)
        .orderBy('date', descending: true));
    return snapshot.docs.length < kPrayerRequestPerUserLimit;
  }
}
