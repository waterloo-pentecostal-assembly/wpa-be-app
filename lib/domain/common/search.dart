/// Text search, shared by every searchable collection (users, challenge
/// groups).
///
/// Firestore has no case-insensitive or substring queries, so each
/// searchable document stores `search_tokens`: every prefix (2 to 15
/// characters) of every lower-cased word of its searchable text. **The
/// backend writes them** (wpa-be-firebase triggers); the app only queries
/// them. A search matches documents whose tokens contain every word typed,
/// so each word matches the start of a word, in any order.
///
/// The backend must tokenize exactly like [searchTokens] (see
/// docs/firestore/challenge_groups.md).
library;

import 'dart:math';

/// Name of the token field on searchable documents.
const kSearchTokensField = 'search_tokens';

/// Tokens are word prefixes of [kMinSearchTokenLength] to
/// [kMaxSearchTokenLength] characters; longer query words are cut to the
/// maximum, shorter ones are ignored.
const kMinSearchTokenLength = 2;
const kMaxSearchTokenLength = 15;

final _nonWordChars = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Lower-cased words of [text] (letters and digits).
List<String> _words(String text) =>
    text.toLowerCase().split(_nonWordChars).where((w) => w.isNotEmpty).toList();

/// The tokens stored for [text]: every 2-15 character prefix of every word,
/// sorted, without duplicates. E.g. `"Night Owls"` →
/// `[ni, nig, nigh, night, ow, owl, owls]`.
List<String> searchTokens(String text) {
  final tokens = <String>{};
  for (final word in _words(text)) {
    final longest = min(word.length, kMaxSearchTokenLength);
    for (var length = kMinSearchTokenLength; length <= longest; length++) {
      tokens.add(word.substring(0, length));
    }
  }
  return tokens.toList()..sort();
}

/// The tokens a query must all match: its words of 2+ characters, cut to 15
/// characters. Empty when nothing can be searched.
List<String> searchQueryTokens(String query) => {
      for (final word in _words(query))
        if (word.length >= kMinSearchTokenLength)
          word.substring(0, min(word.length, kMaxSearchTokenLength)),
    }.toList();

/// Documents fetched per search before the other query words are checked
/// on the device (see `tokenSearch`).
const kSearchFetchLimit = 50;

/// Whether [query] has anything to search for.
bool isSearchableQuery(String query) => searchQueryTokens(query).isNotEmpty;

/// Whether a document with [tokens] matches every query token.
bool matchesSearch(Iterable<String> tokens, List<String> queryTokens) {
  final stored = tokens.toSet();
  return queryTokens.every(stored.contains);
}
