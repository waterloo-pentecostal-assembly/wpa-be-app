import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/bible/entities.dart';
import 'package:wpa_app/domain/bible/verse_reference.dart';

void main() {
  group('formatReference', () {
    final names = {'JHN': 'John', 'PSA': 'Psalms', '1KI': '1 Kings'};
    String format(List<String> ids) =>
        formatReference(ids, bookName: (b) => names[b] ?? b);

    test('a single verse', () {
      expect(format(['JHN.3.16']), 'John 3:16');
    });

    test('groups consecutive verses and separates gaps', () {
      expect(
        format(['JHN.3.16', 'JHN.3.17', 'JHN.3.18', 'JHN.3.20']),
        'John 3:16-18, 20',
      );
    });

    test('new chapters and books', () {
      expect(
        format(['JHN.3.36', 'JHN.4.1', 'JHN.4.2', 'PSA.23.1', '1KI.2.1']),
        'John 3:36; 4:1-2; Psalms 23:1; 1 Kings 2:1',
      );
    });

    test('unknown books use their id; odd ids are kept', () {
      expect(formatReference(['GEN.1.1', 'weird']), 'GEN 1:1; weird');
      expect(formatReference([]), '');
    });
  });

  test('passageIdFor', () {
    expect(passageIdFor('JHN.3.16', 'JHN.3.18'), 'JHN.3.16-JHN.3.18');
    expect(passageIdFor('JHN.3.16', 'JHN.3.16'), 'JHN.3.16');
  });

  test('bookNameOf', () {
    expect(bookNameOf('1 Kings 2:1-3'), '1 Kings');
    expect(bookNameOf('Psalms 23'), 'Psalms');
    expect(bookNameOf('Song of Solomon 2:1'), 'Song of Solomon');
    expect(bookNameOf('JHN'), isNull);
  });

  test('VerseText.number', () {
    expect(const VerseText(verseId: 'JHN.3.16', text: '').number, '16');
    expect(const VerseText(verseId: 'odd', text: '').number, '');
  });

  test('BiblePassage verse ids, text and book name', () {
    const passage = BiblePassage(
      id: 'JHN.3.16-JHN.3.17',
      bibleId: 'kjv',
      reference: 'John 3:16-17',
      blocks: [
        PassageHeading('Love'),
        PassageParagraph([
          VerseSegment(text: '16', verseId: 'JHN.3.16', isVerseNumber: true),
          VerseSegment(text: 'For God  so loved ', verseId: 'JHN.3.16'),
        ]),
        PassageParagraph([
          VerseSegment(text: 'the world. ', verseId: 'JHN.3.16'),
          VerseSegment(text: '17', verseId: 'JHN.3.17', isVerseNumber: true),
          VerseSegment(text: 'For God sent', verseId: 'JHN.3.17'),
        ]),
      ],
    );
    expect(passage.verseIds, ['JHN.3.16', 'JHN.3.17']);
    expect(passage.verseText('JHN.3.16'), 'For God so loved the world.');
    expect(passage.verseText('JHN.3.18'), '');
    expect(passage.bookName, 'John');
  });

  test('groupByChapter', () {
    expect(
      groupByChapter(
          ['JHN.3.18', 'PSA.23.1', 'JHN.3.16', 'JHN.4.1', 'odd', 'JHN.3.16']),
      [
        ['JHN.3.16', 'JHN.3.18'],
        ['PSA.23.1'],
        ['JHN.4.1'],
        ['odd'],
      ],
    );
    expect(groupByChapter([]), isEmpty);
  });
}
