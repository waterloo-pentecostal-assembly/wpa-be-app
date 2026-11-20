import 'package:equatable/equatable.dart';

import 'verse_reference.dart';

/// A Bible version (translation) available through the Bible API.
class BibleVersion extends Equatable {
  const BibleVersion({
    required this.id,
    required this.name,
    required this.abbreviation,
    this.description = '',
    this.languageId = '',
    this.languageName = '',
  });

  /// Bible API id, e.g. `de4e12af7f28f599-02`.
  final String id;

  /// e.g. `King James (Authorised) Version`.
  final String name;

  /// e.g. `KJV`.
  final String abbreviation;
  final String description;

  /// ISO 639-3 code, e.g. `eng`.
  final String languageId;

  /// e.g. `English`.
  final String languageName;

  @override
  List<Object?> get props =>
      [id, name, abbreviation, description, languageId, languageName];
}

/// A run of text in a passage. Text that belongs to a verse has its
/// [verseId] (e.g. `JHN.3.16`); headings and other text outside verses have
/// none.
class VerseSegment extends Equatable {
  const VerseSegment({
    required this.text,
    this.verseId,
    this.isVerseNumber = false,
  });

  final String text;
  final String? verseId;

  /// The verse number shown at the start of a verse (its [text] is the
  /// number, e.g. `16`).
  final bool isVerseNumber;

  @override
  List<Object?> get props => [text, verseId, isVerseNumber];
}

/// A block of a passage: a [PassageHeading] or a [PassageParagraph].
sealed class PassageBlock extends Equatable {
  const PassageBlock();
}

/// A section heading (e.g. `The Beginning`). It is not part of any verse.
class PassageHeading extends PassageBlock {
  const PassageHeading(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// A paragraph (or poetry line) of verse text.
class PassageParagraph extends PassageBlock {
  const PassageParagraph(this.segments, {this.isIndented = false});

  final List<VerseSegment> segments;

  /// Poetry and indented paragraphs.
  final bool isIndented;

  @override
  List<Object?> get props => [segments, isIndented];
}

/// A passage of the Bible, as returned by the Bible API.
class BiblePassage extends Equatable {
  const BiblePassage({
    required this.id,
    required this.bibleId,
    required this.reference,
    required this.blocks,
    this.copyright = '',
  });

  /// Bible API passage id, e.g. `JHN.3.16-JHN.3.18`.
  final String id;
  final String bibleId;

  /// Human readable reference, e.g. `John 3:16-18`.
  final String reference;
  final List<PassageBlock> blocks;
  final String copyright;

  /// Ids of the verses in the passage, in order, each once.
  List<String> get verseIds => [
        ...{
          for (final block in blocks)
            if (block is PassageParagraph)
              for (final segment in block.segments)
                if (segment.verseId != null) segment.verseId!,
        },
      ];

  /// The text of [verseId] without its verse number, trimmed. Empty when the
  /// verse is not in the passage.
  String verseText(String verseId) => [
        for (final block in blocks)
          if (block is PassageParagraph)
            for (final segment in block.segments)
              if (segment.verseId == verseId && !segment.isVerseNumber)
                segment.text,
      ].join().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// The book name used in [reference] (e.g. `1 Kings` for
  /// `1 Kings 2:1-3`), or `null` when it can't be told.
  String? get bookName => bookNameOf(reference);

  @override
  List<Object?> get props => [id, bibleId, reference, blocks, copyright];
}

/// The text of one verse in a given Bible version.
class VerseText extends Equatable {
  const VerseText({required this.verseId, required this.text});

  final String verseId;

  /// Empty when the version has no such verse.
  final String text;

  /// The verse number, e.g. `16` for `JHN.3.16`.
  String get number => VerseRef.tryParse(verseId)?.verse ?? '';

  @override
  List<Object?> get props => [verseId, text];
}

/// `16 For God so loved… 17 For God did not…` (verses missing from a
/// version are left out).
String joinVerses(List<VerseText> verses) => [
      for (final v in verses)
        if (v.text.isNotEmpty) '${v.number} ${v.text}'.trim(),
    ].join(' ');

/// Verses the signed-in user saved on a series day ([seriesId] /
/// [contentId]), with an optional [note]. One record per save: adding,
/// editing or deleting the note only changes [note].
///
/// A saved verse shows only on the series day it was saved from, and only
/// while that day is read in the version it was saved in ([isIn]). The
/// verses' text is not stored; it is read from the Bible API when shown.
class SavedVerse extends Equatable {
  const SavedVerse({
    required this.id,
    required this.verseIds,
    required this.reference,
    required this.bibleId,
    required this.versionAbbreviation,
    required this.seriesId,
    required this.contentId,
    required this.createdAt,
    required this.updatedAt,
    this.seriesTitle = '',
    this.day,
    this.note,
  });

  final String id;

  /// The saved verses, in reading order.
  final List<String> verseIds;

  /// e.g. `John 3:16-17`.
  final String reference;

  /// Version the verses were read in when saved.
  final String bibleId;
  final String versionAbbreviation;

  /// The user's note; `null` when there is none.
  final String? note;

  /// The series day the verses were saved from: the saved verse belongs to
  /// it (it is only shown there, and "Open reading" goes back to it).
  final String seriesId;
  final String contentId;

  /// Title of the series when saved (e.g. `Hope in Hard Times`); '' if the
  /// series couldn't be loaded.
  final String seriesTitle;

  /// 1-based day of the series ([contentId]'s day), if known.
  final int? day;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasNote => note != null;

  /// Whether this was saved while reading the version [bibleId]: in the
  /// reader it is only highlighted (and its note shown) in that version.
  bool isIn(String? bibleId) => this.bibleId == bibleId;

  /// A copy with [note] (`null` removes it).
  SavedVerse withNote(String? note) => SavedVerse(
        id: id,
        verseIds: verseIds,
        reference: reference,
        bibleId: bibleId,
        versionAbbreviation: versionAbbreviation,
        note: note,
        seriesId: seriesId,
        contentId: contentId,
        seriesTitle: seriesTitle,
        day: day,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        verseIds,
        reference,
        bibleId,
        versionAbbreviation,
        note,
        seriesId,
        contentId,
        seriesTitle,
        day,
        createdAt,
        updatedAt,
      ];
}

/// A [SavedVerse] to be created (the id and dates are assigned on save).
class NewSavedVerse extends Equatable {
  const NewSavedVerse({
    required this.verseIds,
    required this.reference,
    required this.bibleId,
    required this.versionAbbreviation,
    required this.seriesId,
    required this.contentId,
    this.seriesTitle = '',
    this.day,
    this.note,
  });

  final List<String> verseIds;
  final String reference;
  final String bibleId;
  final String versionAbbreviation;
  final String? note;
  final String seriesId;
  final String contentId;
  final String seriesTitle;
  final int? day;

  @override
  List<Object?> get props => [
        verseIds,
        reference,
        bibleId,
        versionAbbreviation,
        note,
        seriesId,
        contentId,
        seriesTitle,
        day,
      ];
}
