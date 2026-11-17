import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/common/paging.dart';

/// [PageCursor] wrapping the last Firestore document of a page.
class FirestorePageCursor extends PageCursor {
  const FirestorePageCursor(this.snapshot);

  final DocumentSnapshot snapshot;
}

extension PagedQueryX on Query {
  /// Applies [after] (when it is a [FirestorePageCursor]) and [limit].
  Query page({required int limit, PageCursor? after}) {
    var query = this;
    if (after is FirestorePageCursor) {
      query = query.startAfterDocument(after.snapshot);
    }
    return query.limit(limit);
  }
}

/// Next cursor for a page: none when fewer than [limit] documents came back.
PageCursor? nextCursorFor(QuerySnapshot snapshot, int limit) {
  if (snapshot.docs.isEmpty || snapshot.docs.length < limit) return null;
  return FirestorePageCursor(snapshot.docs.last);
}
