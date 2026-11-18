import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/infrastructure/common/firestore_data.dart';

final throwsMissingKey = throwsA(isA<ApplicationException>()
    .having((e) => e.code, 'code', ApplicationExceptionCode.missingKey));

void main() {
  group('FirestoreFields', () {
    final data = <String, dynamic>{
      'title': 'T',
      'flag': true,
      'count': 3,
      'double_count': 4.0,
      'when': Timestamp.fromDate(DateTime(2024, 3, 1)),
      'tags': ['a', 1],
      'nested': {'k': 'v'},
      'nothing': null,
    };

    test('require returns typed values', () {
      expect(data.require<String>('title'), 'T');
      expect(data.require<bool>('flag'), isTrue);
      expect(data.requireDate('when'), DateTime(2024, 3, 1));
      expect(data.requireMap('nested'), {'k': 'v'});
    });

    test('require throws missingKey when missing, null or the wrong type', () {
      expect(() => data.require<String>('absent'), throwsMissingKey);
      expect(() => data.require<String>('nothing'), throwsMissingKey);
      expect(() => data.require<String>('flag'), throwsMissingKey);
      expect(() => data.requireDate('title'), throwsMissingKey);
    });

    test('optional falls back when missing or the wrong type', () {
      expect(data.optional('flag', false), isTrue);
      expect(data.optional('absent', false), isFalse);
      expect(data.optional('title', false), isFalse);
      expect(data.nullable<String>('nothing'), isNull);
      expect(data.nullable<String>('flag'), isNull);
    });

    test('integers accept doubles written by other clients', () {
      expect(data.requireInt('count'), 3);
      expect(data.requireInt('double_count'), 4);
      expect(data.optionalInt('absent'), 0);
      expect(data.optionalInt('title', 7), 7);
    });

    test('stringList stringifies items and reads missing as empty', () {
      expect(data.stringList('tags'), ['a', '1']);
      expect(data.stringList('absent'), isEmpty);
    });

    test('pendingDate reads a pending server timestamp as now', () {
      final before = DateTime.now();
      expect(data.pendingDate('nothing').isBefore(before), isFalse);
      expect(data.pendingDate('when'), DateTime(2024, 3, 1));
    });
  });
}
