import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/common/search.dart';
import 'firestore_data.dart';

/// Runs a token search (see `domain/common/search.dart`) on top of [base]:
/// Firestore allows one `array-contains` per query, so it filters on the
/// longest (most selective) query token, fetches at most [fetchLimit]
/// documents, and keeps those whose tokens contain every query token.
///
/// [base] needs a composite index with `search_tokens` (array-contains)
/// for its equality filters. Returns nothing when [queryTokens] is empty.
Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> tokenSearch(
  Query<Map<String, dynamic>> base,
  List<String> queryTokens, {
  required int fetchLimit,
}) async {
  if (queryTokens.isEmpty) return const [];
  final longest = queryTokens.reduce((a, b) => b.length > a.length ? b : a);
  final snapshot = await base
      .where(kSearchTokensField, arrayContains: longest)
      .limit(fetchLimit)
      .get();
  return snapshot.docs
      .where((doc) =>
          matchesSearch(doc.data().stringList(kSearchTokensField), queryTokens))
      .toList();
}
