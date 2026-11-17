import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/common/paging.dart';
import '../../domain/testimonies/entities.dart';
import '../../domain/testimonies/exceptions.dart';
import '../../domain/testimonies/interfaces.dart';
import '../../domain/testimonies/rules.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import '../common/firestore_page_cursor.dart';
import '../common/helpers.dart';
import '../common/user_snippet_dto.dart';
import 'testimonies_dto.dart';

class TestimoniesRepository implements ITestimoniesRepository {
  TestimoniesRepository(
    this._firestore,
    this._firebaseStorageService,
    this._firebaseFirestoreService,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final ISession _session;

  CollectionReference get _collection => _firestore.collection('testimonies');

  Future<List<Testimony>> _toDomain(
          List<DocumentSnapshot> docs, String userId) =>
      Future.wait(docs.map(
        (doc) =>
            TestimoniesDto.fromFirestore(doc, userId, _firebaseStorageService),
      ));

  Future<QuerySnapshot> _get(Query query) async {
    try {
      return await query.get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<Testimony> createTestimony({
    required String request,
    required bool isAnonymous,
  }) async {
    final user = _session.requireUser();
    final DocumentSnapshot snapshot;
    try {
      final ref = await _collection.add(TestimoniesDto.newDocument(
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
    return TestimoniesDto.fromFirestore(
        snapshot, user.id, _firebaseStorageService);
  }

  @override
  Future<void> deleteTestimony({required String id}) async {
    try {
      await _collection.doc(id).delete();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  Future<List<Testimony>> _mine({required bool closed}) async {
    final user = _session.requireUser();
    final snapshot = await _get(_collection
        .where('user_id', isEqualTo: user.id)
        .where('is_archived', isEqualTo: closed)
        .orderBy('date', descending: true));
    return _toDomain(snapshot.docs, user.id);
  }

  @override
  Future<List<Testimony>> getMyTestimonies() => _mine(closed: false);

  @override
  Future<List<Testimony>> getMyArchivedTestimonies() => _mine(closed: true);

  @override
  Future<Testimony> closeTestimony({required String id}) async {
    final user = _session.requireUser();
    final DocumentSnapshot snapshot;
    try {
      final ref = _collection.doc(id);
      await ref.update({'is_archived': true});
      snapshot = await ref.get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    return TestimoniesDto.fromFirestore(
        snapshot, user.id, _firebaseStorageService);
  }

  @override
  Future<PageResult<Testimony>> getTestimonies({
    required int limit,
    PageCursor? after,
  }) async {
    final user = _session.requireUser();
    final snapshot = await _get(_collection
        .where('is_approved', isEqualTo: true)
        .where('is_archived', isEqualTo: false)
        .orderBy('date', descending: true)
        .page(limit: limit, after: after));
    return PageResult(
      items: await _toDomain(snapshot.docs, user.id),
      nextCursor: nextCursorFor(snapshot, limit),
    );
  }

  @override
  Future<void> praiseTestimony({required String id}) async {
    final user = _session.requireUser();
    try {
      // Transaction to avoid stale data.
      await _firestore.runTransaction((transaction) async {
        final ref = _collection.doc(id);
        final snapshot = await transaction.get(ref);
        if (snapshot.data() == null) {
          throw const TestimoniesException(
            code: TestimoniesExceptionCode.testimonyNotFound,
            message: 'Testimony not found',
          );
        }
        final List<dynamic> reactedBy = findOrDefaultTo(
          snapshot.data() as Map<String, dynamic>,
          'praised_by',
          [],
        );
        transaction.update(ref, {
          'praised_by': [...reactedBy, user.id]
        });
      });
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> reportTestimony({required String id}) async {
    final user = _session.requireUser();
    try {
      await _firestore.runTransaction((transaction) async {
        final ref = _collection.doc(id);
        final snapshot = await transaction.get(ref);
        final data = (snapshot.data() ?? {}) as Map<String, dynamic>;
        final List<dynamic> reportedBy = data['reported_by'] ?? [];
        if (reportedBy.contains(user.id)) {
          throw const TestimoniesException(
            code: TestimoniesExceptionCode.alreadyReported,
            message: 'You already reported this testimony',
          );
        }
        transaction.update(ref, {
          'reported_by': [...reportedBy, user.id],
          'is_approved': false,
        });
      });
    } on TestimoniesException {
      rethrow;
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<bool> canAddTestimony() async {
    final user = _session.requireUser();
    final snapshot = await _get(_collection
        .where('user_id', isEqualTo: user.id)
        .where('is_approved', isEqualTo: true)
        .orderBy('date', descending: true));
    return snapshot.docs.length < kTestimoniesPerUserLimit;
  }
}
