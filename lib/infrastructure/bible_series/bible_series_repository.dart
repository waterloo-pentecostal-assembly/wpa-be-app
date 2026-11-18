import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../services/firebase_storage_service.dart';
import '../common/firestore_data.dart';
import '../common/firestore_errors.dart';
import 'bible_series_documents.dart';

class BibleSeriesRepository implements IBibleSeriesRepository {
  BibleSeriesRepository(
    this._firestore,
    this._firebaseStorageService,
    this._session,
  );

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;
  final ISession _session;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('bible_series');

  @override
  Future<List<BibleSeries>> getBibleSeries({
    required int limit,
    bool isActive = false,
  }) async {
    final isAdmin = _session.currentUser?.isAdmin ?? false;
    Query<Map<String, dynamic>> query =
        _collection.orderBy('start_date', descending: true);
    if (!isAdmin) query = query.where('is_visible', isEqualTo: true);
    if (isActive) query = query.where('is_active', isEqualTo: true);
    final snapshot = await guardFirestore(query.limit(limit).get);
    return parseAllSkippingInvalid(
        snapshot.docs, (doc) => parseBibleSeries(doc, _firebaseStorageService));
  }

  @override
  Future<BibleSeries> getBibleSeriesDetails({
    required String bibleSeriesId,
  }) =>
      guardFirestore(() async {
        final document = await _collection.doc(bibleSeriesId).get();
        if (document.data() == null) {
          throw BibleSeriesException(
            code: BibleSeriesExceptionCode.noSeriesContent,
            message: 'Unable to find requested Bible Series',
            details: 'Bible series $bibleSeriesId not found',
          );
        }
        return parseBibleSeries(document, _firebaseStorageService);
      });

  @override
  Future<SeriesContent> getContentDetails({
    required String bibleSeriesId,
    required String seriesContentId,
  }) =>
      guardFirestore(() async {
        final document = await _collection
            .doc(bibleSeriesId)
            .collection('series_content')
            .doc(seriesContentId)
            .get();
        if (document.data() == null) {
          throw const BibleSeriesException(
            code: BibleSeriesExceptionCode.noContentInfo,
            message: 'Cannot find content details',
          );
        }
        return parseSeriesContent(document);
      });

  /// Whether the newest visible series is active. Reads the flag directly
  /// (no need to resolve the cover image URL).
  @override
  Future<bool> hasActiveBibleSeries() => guardFirestore(() async {
        final snapshot = await _collection
            .orderBy('start_date', descending: true)
            .where('is_visible', isEqualTo: true)
            .limit(1)
            .get();
        if (snapshot.docs.isEmpty) return false;
        return snapshot.docs.first.data().optional('is_active', false);
      });
}
