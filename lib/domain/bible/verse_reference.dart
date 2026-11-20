/// A Bible API verse id such as `JHN.3.16`, split into its parts.
class VerseRef {
  const VerseRef(this.book, this.chapter, this.verse);

  /// e.g. `JHN`.
  final String book;

  /// e.g. `3`.
  final String chapter;

  /// e.g. `16`.
  final String verse;

  int? get verseNumber => int.tryParse(verse);

  /// `null` unless [verseId] has the form `BOOK.CHAPTER.VERSE`.
  static VerseRef? tryParse(String verseId) {
    final parts = verseId.split('.');
    if (parts.length != 3 || parts.any((p) => p.isEmpty)) return null;
    return VerseRef(parts[0], parts[1], parts[2]);
  }
}

/// The Bible API passage id covering [first] to [last], e.g.
/// `JHN.3.16-JHN.3.18` (or just `JHN.3.16` for a single verse).
String passageIdFor(String first, String last) =>
    first == last ? first : '$first-$last';

/// Splits [verseIds] (in reading order) into groups that one passage request
/// can cover: verses of the same book and chapter, in order of first
/// appearance. Request each group from its first to its last verse (a chapter
/// never exceeds the API's 200 verse limit) and keep only its verses. Ids
/// that can't be parsed get a group of their own.
List<List<String>> groupByChapter(List<String> verseIds) {
  final groups = <String, List<String>>{};
  for (final id in verseIds) {
    final ref = VerseRef.tryParse(id);
    final key = ref == null ? id : '${ref.book}.${ref.chapter}';
    final group = groups.putIfAbsent(key, () => []);
    if (!group.contains(id)) group.add(id);
  }
  return [
    for (final group in groups.values)
      group
        ..sort((a, b) {
          final x = VerseRef.tryParse(a)?.verseNumber;
          final y = VerseRef.tryParse(b)?.verseNumber;
          return x == null || y == null ? 0 : x.compareTo(y);
        }),
  ];
}

final _bookName = RegExp(r'^(.+?)\s+\d+(?::\d+)?');

/// The book name of a human readable reference: `1 Kings` for
/// `1 Kings 2:1-3`, `Psalms` for `Psalms 23`. `null` if there is none.
String? bookNameOf(String reference) =>
    _bookName.firstMatch(reference.trim())?.group(1);

/// A human readable reference for [verseIds] (in reading order), grouping
/// consecutive verses: `John 3:16-18, 20; 4:1; Psalms 23:1`. [bookName]
/// names a book id (e.g. `JHN` → `John`); by default the id is used.
String formatReference(
  List<String> verseIds, {
  String Function(String bookId)? bookName,
}) {
  final name = bookName ?? (id) => id;
  final parts = <String>[];
  String? book;
  String? chapter;
  var verses = <String>[];

  void flushVerses() {
    if (verses.isEmpty) return;
    parts[parts.length - 1] += verses.join(', ');
    verses = [];
  }

  int? rangeStart;
  int? rangeEnd;
  void flushRange() {
    if (rangeStart == null) return;
    verses
        .add(rangeStart == rangeEnd ? '$rangeStart' : '$rangeStart-$rangeEnd');
    rangeStart = null;
    rangeEnd = null;
  }

  for (final id in verseIds) {
    final ref = VerseRef.tryParse(id);
    if (ref == null) {
      flushRange();
      flushVerses();
      parts.add(id);
      book = null;
      chapter = null;
      continue;
    }
    final number = ref.verseNumber;
    if (ref.book == book && ref.chapter == chapter) {
      if (number != null && rangeEnd != null && number == rangeEnd! + 1) {
        rangeEnd = number;
        continue;
      }
      flushRange();
    } else {
      flushRange();
      flushVerses();
      parts.add(ref.book == book
          ? '${ref.chapter}:'
          : '${name(ref.book)} ${ref.chapter}:');
      book = ref.book;
      chapter = ref.chapter;
    }
    if (number != null) {
      rangeStart = number;
      rangeEnd = number;
    } else {
      verses.add(ref.verse);
    }
  }
  flushRange();
  flushVerses();
  return parts.join('; ');
}
