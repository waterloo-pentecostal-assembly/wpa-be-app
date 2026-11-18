import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/common/paging.dart';
import '../../domain/user_profile/entities.dart';
import '../../services/firebase_storage_service.dart';
import '../common/firestore_data.dart';
import '../common/firestore_errors.dart';
import '../common/firestore_page_cursor.dart';
import '../common/user_snippet.dart';

/// The fields shared by `prayer_requests` and `testimonies` documents,
/// already resolved for the signed-in user.
class PostDocument {
  const PostDocument({
    required this.id,
    required this.userId,
    required this.body,
    required this.reactedBy,
    required this.reportedBy,
    required this.isApproved,
    required this.isAnonymous,
    required this.isClosed,
    required this.date,
    required this.author,
    required this.signedInUserId,
  });

  final String id;
  final String userId;
  final String body;
  final List<String> reactedBy;
  final List<String> reportedBy;
  final bool isApproved;
  final bool isAnonymous;
  final bool isClosed;
  final DateTime date;
  final UserSnippet author;
  final String signedInUserId;

  bool get isMine => userId == signedInUserId;
  bool get hasReacted => reactedBy.contains(signedInUserId);
  bool get hasReported => reportedBy.contains(signedInUserId);
}

/// What differs between the prayer request and testimony collections.
class PostCollection<T> {
  const PostCollection({
    required this.name,
    required this.reactedByField,
    required this.closedField,
    required this.perUserLimit,
    required this.toEntity,
    required this.notFound,
    required this.alreadyReported,
  });

  /// Collection name, e.g. `prayer_requests`.
  final String name;

  /// e.g. `prayed_by` / `praised_by`.
  final String reactedByField;

  /// e.g. `is_answered` / `is_archived`.
  final String closedField;

  /// Approved posts a user may have at once.
  final int perUserLimit;

  final T Function(PostDocument doc) toEntity;
  final BaseApplicationException Function() notFound;
  final BaseApplicationException Function() alreadyReported;
}

/// Stateless Firestore access shared by the prayer request and testimony
/// repositories and the admin approval queues. Every document written is
/// identical to the pre-refactor app (see the repository tests).
class FirestorePostStore<T> {
  FirestorePostStore(this._firestore, this._storage, this._session, this._c);

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _storage;
  final ISession _session;
  final PostCollection<T> _c;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_c.name);

  Future<T> _parse(DocumentSnapshot doc, String signedInUserId) async {
    final data = dataOf(doc);
    return _c.toEntity(PostDocument(
      id: doc.id,
      userId: data.require<String>('user_id'),
      body: data.require<String>('request'),
      reactedBy: data.stringList(_c.reactedByField),
      reportedBy: data.stringList('reported_by'),
      isApproved: data.optional('is_approved', false),
      isAnonymous: data.require<bool>('is_anonymous'),
      isClosed: data.optional(_c.closedField, false),
      date: data.requireDate('date'),
      author: await parseUserSnippet(data.requireMap('user_snippet'), _storage),
      signedInUserId: signedInUserId,
    ));
  }

  Future<List<T>> _list(Query query) async {
    final userId = _session.requireUser().id;
    final snapshot = await guardFirestore(query.get);
    return parseAllSkippingInvalid(snapshot.docs, (doc) => _parse(doc, userId));
  }

  /// Re-reads a document after a write and parses it.
  Future<T> _reread(DocumentReference ref) async {
    final userId = _session.requireUser().id;
    return guardFirestore(() async => _parse(await ref.get(), userId));
  }

  /// Approved, open posts, newest first.
  Future<PageResult<T>> page({required int limit, PageCursor? after}) async {
    final userId = _session.requireUser().id;
    final snapshot = await guardFirestore(_collection
        .where('is_approved', isEqualTo: true)
        .where(_c.closedField, isEqualTo: false)
        .orderBy('date', descending: true)
        .page(limit: limit, after: after)
        .get);
    return PageResult(
      items: await parseAllSkippingInvalid(
          snapshot.docs, (doc) => _parse(doc, userId)),
      nextCursor: nextCursorFor(snapshot, limit),
    );
  }

  /// The current user's open ([closed] false) or closed posts, newest first.
  Future<List<T>> mine({required bool closed}) async => _list(_collection
      .where('user_id', isEqualTo: _session.requireUser().id)
      .where(_c.closedField, isEqualTo: closed)
      .orderBy('date', descending: true));

  /// Whether the current user has fewer approved posts than the limit.
  Future<bool> canAdd() async {
    final userId = _session.requireUser().id;
    final count = await guardFirestore(() async {
      final snapshot = await _collection
          .where('user_id', isEqualTo: userId)
          .where('is_approved', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    });
    return count < _c.perUserLimit;
  }

  /// Posts start unapproved; moderation sets `is_approved`.
  Future<T> create({required String body, required bool isAnonymous}) async {
    final user = _session.requireUser();
    final ref = await guardFirestore(() => _collection.add({
          'date': Timestamp.now(),
          'is_anonymous': isAnonymous,
          'is_approved': false,
          _c.closedField: false,
          'request': body,
          'user_id': user.id,
          'user_snippet': userSnippetDocument(user),
        }));
    return _reread(ref);
  }

  Future<void> delete(String id) =>
      guardFirestore(() => _collection.doc(id).delete());

  Future<T> close(String id) async {
    final ref = _collection.doc(id);
    await guardFirestore(() => ref.update({_c.closedField: true}));
    return _reread(ref);
  }

  /// Adds the current user to the reaction list (prayed / amen).
  Future<void> react(String id) async {
    final userId = _session.requireUser().id;
    await guardFirestore(() => _firestore.runTransaction((transaction) async {
          final ref = _collection.doc(id);
          final data = (await transaction.get(ref)).data();
          if (data == null) throw _c.notFound();
          transaction.update(ref, {
            _c.reactedByField: [
              ...data.optional<List>(_c.reactedByField, const []),
              userId,
            ],
          });
        }));
  }

  /// Reports the post and resets `is_approved` so it is re-moderated.
  Future<void> report(String id) async {
    final userId = _session.requireUser().id;
    await guardFirestore(() => _firestore.runTransaction((transaction) async {
          final ref = _collection.doc(id);
          final data = (await transaction.get(ref)).data() ?? {};
          final reportedBy = data.optional<List>('reported_by', const []);
          if (reportedBy.contains(userId)) throw _c.alreadyReported();
          transaction.update(ref, {
            'reported_by': [...reportedBy, userId],
            'is_approved': false,
          });
        }));
  }

  /// Posts awaiting moderation (admin queue).
  Future<List<T>> unapproved() =>
      _list(_collection.where('is_approved', isEqualTo: false));

  Future<void> approve(String id) =>
      guardFirestore(() => _collection.doc(id).update({'is_approved': true}));
}
