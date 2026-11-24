import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/challenge_groups/entities.dart';
import '../../domain/challenge_groups/interfaces.dart';
import '../../domain/challenge_groups/rules.dart';
import '../../domain/common/search.dart';
import '../../services/firebase_storage_service.dart';
import '../common/firestore_data.dart';
import '../common/token_search.dart';
import 'challenge_group_documents.dart';

/// People search over `users/{uid}`: verified users, by the `search_tokens`
/// of their first and last name, which the backend keeps up to date (see
/// `domain/common/search.dart`).
class UserDirectoryRepository implements IUserDirectoryRepository {
  UserDirectoryRepository(this._firestore, this._storage, this._session);

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _storage;
  final ISession _session;

  @override
  Future<List<DirectoryUser>> search(
    String query, {
    int limit = kPeopleSearchLimit,
  }) async {
    final me = _session.currentUser?.id;
    // Composite index: is_verified + search_tokens (array-contains).
    final docs = await tokenSearch(
      _firestore.collection('users').where('is_verified', isEqualTo: true),
      searchQueryTokens(query),
      fetchLimit: kSearchFetchLimit,
    );
    final users = await parseAllSkippingInvalid(
      docs.where((doc) => doc.id != me),
      (doc) => directoryUserFromFirestore(doc.id, doc.data(), _storage),
    );
    users.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return users.take(limit).toList();
  }
}
