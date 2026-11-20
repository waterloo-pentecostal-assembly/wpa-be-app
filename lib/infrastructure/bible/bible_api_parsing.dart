import '../../domain/bible/entities.dart';
import '../../domain/bible/exceptions.dart';
import '../../domain/bible/verse_reference.dart';
import '../common/firestore_data.dart';

/// Parses a passage response: `{"data": {"id", "reference", "content",
/// "copyright"}}` (the bare `data` object is accepted too).
///
/// `content` is normally the `content-type=json` node tree. Plain text
/// (`content-type=text`, with inline `[16]` verse markers) is accepted as a
/// fallback, with verse ids inferred from [passageId].
BiblePassage parseBiblePassage({
  required String bibleId,
  required String passageId,
  required Object? json,
}) {
  final data = _data(json, 'Passage $passageId');
  if (data is! Map) throw _passageError(passageId, json);
  final map = Map<String, dynamic>.from(data);
  final content = map['content'];
  final List<PassageBlock> blocks;
  if (content is List) {
    blocks = parsePassageContent(content);
  } else if (content is String) {
    blocks = parsePassageText(content, passageId: passageId);
  } else {
    throw _passageError(passageId, json);
  }
  return BiblePassage(
    id: map.optional('id', passageId),
    bibleId: map.optional('bibleId', bibleId),
    reference: map.optional('reference', passageId),
    blocks: blocks,
    copyright: map.optional('copyright', '').trim(),
  );
}

/// Parses a `GET /v1/bibles` response (`{"data": [...]}`). Entries without
/// an id are skipped.
List<BibleVersion> parseBibleVersions(Object? json) {
  final data = _data(json, 'Bibles');
  if (data is! List) {
    throw BibleException(
      code: BibleExceptionCode.versionsUnavailable,
      message: 'Unable to load Bible versions',
      details: 'Bibles: unexpected response $json',
    );
  }
  return [
    for (final item in data)
      if (item is Map && item['id'] is String)
        _version(Map<String, dynamic>.from(item)),
  ];
}

BibleVersion _version(Map<String, dynamic> m) {
  final language = m['language'] is Map
      ? Map<String, dynamic>.from(m['language'] as Map)
      : const <String, dynamic>{};
  String text(Map<String, dynamic> map, String key) =>
      map.optional<String>(key, '').trim();
  final name = text(m, 'name');
  final abbreviation = text(m, 'abbreviationLocal').isNotEmpty
      ? text(m, 'abbreviationLocal')
      : text(m, 'abbreviation');
  return BibleVersion(
    id: m['id'] as String,
    name: name.isNotEmpty ? name : text(m, 'nameLocal'),
    abbreviation: abbreviation,
    description: text(m, 'description'),
    languageId: text(language, 'id'),
    languageName: text(language, 'name'),
  );
}

Object? _data(Object? json, String what) =>
    json is Map && json.containsKey('data') ? json['data'] : json;

BibleException _passageError(String passageId, Object? json) => BibleException(
      code: BibleExceptionCode.passageUnavailable,
      message: 'Unable to load scripture',
      details: 'Passage $passageId: unexpected response $json',
    );

// ---------------------------------------------------------------------------
// content-type=json
// ---------------------------------------------------------------------------

/// Builds the blocks of a `content-type=json` passage: a list of `para`
/// nodes whose (possibly nested) `text` items carry `attrs.verseId`, with a
/// `verse` tag before each verse holding its number.
///
/// Paragraphs without verse text (section headings, references) become
/// [PassageHeading]s; footnotes are dropped.
List<PassageBlock> parsePassageContent(List<dynamic> nodes) {
  final blocks = <PassageBlock>[];
  for (final node in nodes) {
    if (node is! Map) continue;
    final segments = <VerseSegment>[];
    _collect(node['items'], segments);
    final hasVerses = segments.any((s) => s.verseId != null || s.isVerseNumber);
    if (!hasVerses) {
      final text = segments.map((s) => s.text).join().trim();
      if (text.isNotEmpty) blocks.add(PassageHeading(text));
      continue;
    }
    final style = _attr(node, 'style') ?? '';
    blocks.add(PassageParagraph(
      segments,
      isIndented: style.startsWith('q') || style.startsWith('pi'),
    ));
  }
  return _withVerseNumberIds(blocks);
}

String? _attr(Map node, String key) {
  final attrs = node['attrs'];
  if (attrs is! Map) return null;
  final value = attrs[key];
  return value is String ? value : null;
}

void _collect(Object? items, List<VerseSegment> out) {
  if (items is! List) return;
  for (final item in items) {
    if (item is! Map) continue;
    if (item['type'] == 'text') {
      final text = item['text'];
      if (text is String && text.isNotEmpty) {
        out.add(VerseSegment(text: text, verseId: _attr(item, 'verseId')));
      }
      continue;
    }
    switch (item['name']) {
      case 'note':
        break;
      case 'verse':
        final inner = <VerseSegment>[];
        _collect(item['items'], inner);
        final number =
            _attr(item, 'number') ?? inner.map((s) => s.text).join().trim();
        // Provisional id from `sid` ("JHN 3:16"); replaced by the id of the
        // verse's text in [_withVerseNumberIds].
        final sid = _attr(item, 'sid');
        out.add(VerseSegment(
          text: number,
          verseId: sid?.replaceAll(RegExp(r'[ :]'), '.'),
          isVerseNumber: true,
        ));
      default:
        _collect(item['items'], out);
    }
  }
}

/// Gives each verse number the verse id of the text that follows it (its
/// `sid` is kept when no text follows, e.g. a verse omitted by the version).
List<PassageBlock> _withVerseNumberIds(List<PassageBlock> blocks) {
  final result = List<PassageBlock>.of(blocks);
  String? next; // id of the closest verse text after the current position
  for (var b = result.length - 1; b >= 0; b--) {
    final block = result[b];
    if (block is! PassageParagraph) continue;
    final segments = List<VerseSegment>.of(block.segments);
    for (var i = segments.length - 1; i >= 0; i--) {
      final s = segments[i];
      if (s.isVerseNumber) {
        segments[i] = VerseSegment(
          text: s.text,
          verseId: next ?? s.verseId,
          isVerseNumber: true,
        );
        next = null;
      } else if (s.verseId != null) {
        next = s.verseId;
      }
    }
    result[b] = PassageParagraph(segments, isIndented: block.isIndented);
  }
  return result;
}

// ---------------------------------------------------------------------------
// content-type=text (fallback)
// ---------------------------------------------------------------------------

final _marker = RegExp(r'\[(\d+)\]\s*');

/// Builds the blocks of a plain-text passage. Lines without a verse marker
/// are headings, unless they continue a verse. Verse ids are inferred from
/// the first verse of [passageId] (a verse number lower than the previous
/// one starts the next chapter). Without a parsable [passageId], verses get
/// no id (they show but can't be selected).
List<PassageBlock> parsePassageText(String content,
    {required String passageId}) {
  final first = VerseRef.tryParse(passageId.split('-').first);
  var chapter = int.tryParse(first?.chapter ?? '');
  int? lastNumber;
  String? currentId;
  final blocks = <PassageBlock>[];
  for (final raw in content.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final matches = _marker.allMatches(line).toList();
    if (matches.isEmpty && currentId == null) {
      blocks.add(PassageHeading(line));
      continue;
    }
    final segments = <VerseSegment>[];
    var start = 0;
    for (final m in matches) {
      if (m.start > start) {
        segments.add(VerseSegment(
          text: line.substring(start, m.start),
          verseId: currentId,
        ));
      }
      final number = int.parse(m[1]!);
      if (lastNumber != null && number < lastNumber && chapter != null) {
        chapter++;
      }
      lastNumber = number;
      currentId = first != null && chapter != null
          ? '${first.book}.$chapter.$number'
          : null;
      segments.add(VerseSegment(
        text: '$number',
        verseId: currentId,
        isVerseNumber: true,
      ));
      start = m.end;
    }
    if (start < line.length) {
      segments.add(VerseSegment(
        text: '${line.substring(start)} ',
        verseId: currentId,
      ));
    }
    blocks.add(PassageParagraph(segments));
  }
  return blocks;
}
