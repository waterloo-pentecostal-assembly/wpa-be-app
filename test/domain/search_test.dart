import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/common/search.dart';

void main() {
  group('searchTokens', () {
    test('every 2-15 character prefix of every word, lower-cased', () {
      expect(searchTokens('Night Owls'),
          ['ni', 'nig', 'nigh', 'night', 'ow', 'owl', 'owls']);
    });

    test('split on punctuation and spaces, without duplicates', () {
      final tokens = searchTokens("Late-night readers, 9pm! Readers");
      expect(
          tokens, containsAll(['la', 'late', 'night', 'readers', '9p', '9pm']));
      expect(tokens, isNot(contains('late-night')));
      expect(tokens.where((t) => t == 'readers'), hasLength(1));
    });

    test('skip one-letter words and cap long words', () {
      final tokens = searchTokens('A wonderfullylongname');
      expect(tokens, isNot(contains('a')));
      expect(tokens.map((t) => t.length).reduce((a, b) => a > b ? a : b), 15);
    });

    test('trim stray spaces and handle accents', () {
      expect(searchTokens(' Stephen  Gawne '), searchTokens('stephen gawne'));
      expect(searchTokens('Élan Ñu'), containsAll(['él', 'élan', 'ñu']));
    });
  });

  group('queries', () {
    test('query tokens are the words of 2+ letters, cut to 15', () {
      expect(searchQueryTokens('  Night  o OWL! '), ['night', 'owl']);
      expect(searchQueryTokens('o'), isEmpty);
      expect(searchQueryTokens('wonderfullylongname'), ['wonderfullylong']);
      expect(isSearchableQuery('o k'), isFalse);
      expect(isSearchableQuery('ok'), isTrue);
    });

    test('every query word must start a word, in any order', () {
      final tokens = searchTokens('Mary Ann Smith-Jones');
      expect(matchesSearch(tokens, searchQueryTokens('mary')), isTrue);
      expect(matchesSearch(tokens, searchQueryTokens('ann')), isTrue);
      expect(matchesSearch(tokens, searchQueryTokens('jones mar')), isTrue);
      expect(matchesSearch(tokens, searchQueryTokens('smith bob')), isFalse);
      expect(matchesSearch(tokens, searchQueryTokens('ones')), isFalse);
    });
  });
}
