import '../../domain/bible/entities.dart';
import '../../domain/bible/interfaces.dart';
import '../../domain/bible/verse_reference.dart';

/// The text of [verseIds] in [bibleId], in the given order, read from the
/// Bible API: one passage request per book and chapter (see
/// [groupByChapter]). A verse the version lacks has empty text.
Future<List<VerseText>> fetchVerseTexts(
  IBiblePassageRepository passages, {
  required String bibleId,
  required List<String> verseIds,
}) async {
  final groups = groupByChapter(verseIds);
  final loaded = await Future.wait([
    for (final group in groups)
      passages.getPassage(
        bibleId: bibleId,
        passageId: passageIdFor(group.first, group.last),
      ),
  ]);
  final textOf = {
    for (var i = 0; i < groups.length; i++)
      for (final id in groups[i]) id: loaded[i].verseText(id),
  };
  return [
    for (final id in verseIds) VerseText(verseId: id, text: textOf[id] ?? ''),
  ];
}
