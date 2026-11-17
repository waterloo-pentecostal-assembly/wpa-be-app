import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import 'bible_series_dto.dart';
import 'series_content_dto.dart';

class BibleSeriesRepository implements IBibleSeriesRepository {
  BibleSeriesRepository(
    this._firestore,
    this._firebaseStorageService,
    this._firebaseFirestoreService,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final ISession _session;

  CollectionReference get _collection => _firestore.collection('bible_series');

  /// Converts documents in parallel, skipping malformed ones so that one bad
  /// document does not break the list.
  Future<List<BibleSeries>> _toDomainSkippingInvalid(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final results = await Future.wait(docs.map((doc) async {
      try {
        return await BibleSeriesDto.fromFirestore(doc)
            .toDomain(_firebaseStorageService);
      } catch (_) {
        return null;
      }
    }));
    return results.whereType<BibleSeries>().toList();
  }

  @override
  Future<List<BibleSeries>> getBibleSeries({
    required int limit,
    bool isActive = false,
  }) async {
    final QuerySnapshot snapshot;
    try {
      final isAdmin = _session.currentUser?.isAdmin ?? false;
      Query query = _collection.orderBy('start_date', descending: true);
      if (!isAdmin) query = query.where('is_visible', isEqualTo: true);
      if (isActive) query = query.where('is_active', isEqualTo: true);
      snapshot = await query.limit(limit).get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    return _toDomainSkippingInvalid(snapshot.docs);
  }

  @override
  Future<BibleSeries> getBibleSeriesDetails({
    required String bibleSeriesId,
  }) async {
    final DocumentSnapshot document;
    try {
      document = await _collection.doc(bibleSeriesId).get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    if (document.data() == null) {
      throw BibleSeriesException(
        code: BibleSeriesExceptionCode.noSeriesContent,
        message: 'Unable to find requested Bible Series',
        details: 'Bible series $bibleSeriesId not found',
      );
    }
    return BibleSeriesDto.fromFirestore(document)
        .toDomain(_firebaseStorageService);
  }

  @override
  Future<SeriesContent> getContentDetails({
    required String bibleSeriesId,
    required String seriesContentId,
  }) async {
    final DocumentSnapshot document;
    try {
      document = await _collection
          .doc(bibleSeriesId)
          .collection('series_content')
          .doc(seriesContentId)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    if (document.data() == null) {
      throw const BibleSeriesException(
        code: BibleSeriesExceptionCode.noContentInfo,
        message: 'Cannot find content details',
      );
    }
    return SeriesContentDto.fromFirestore(document).toDomain();
  }

  @override
  Future<bool> hasActiveBibleSeries() async {
    try {
      final snapshot = await _collection
          .orderBy('start_date', descending: true)
          .where('is_visible', isEqualTo: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return false;
      final series = await BibleSeriesDto.fromFirestore(snapshot.docs.first)
          .toDomain(_firebaseStorageService);
      return series.isActive;
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }
}
