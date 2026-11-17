import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/domain/completions/policies.dart';

void main() {
  final content = SeriesContent(
    id: 'c',
    contentType: 'REFLECT',
    date: DateTime.utc(2026, 3, 10),
    title: '',
    subTitle: '',
    body: const [
      TextBody(paragraphs: ['intro']),
      QuestionBody(questions: [
        Question(question: 'Q1', location: [1, 0]),
        Question(question: 'Q2', location: [1, 1]),
      ]),
    ],
  );

  Responses answers(Map<String, String> byQuestion) {
    var r = const Responses();
    byQuestion.forEach((q, text) {
      r = r.withResponse(
        '1',
        q,
        ResponseDetails(type: ResponseType.text, response: text),
      );
    });
    return r;
  }

  test('content with a question accepts responses', () {
    expect(content.isResponsePossible, isTrue);
  });

  test('isOnTime: same UTC day or earlier', () {
    final date = DateTime.utc(2026, 3, 10);
    expect(isOnTime(date, DateTime.utc(2026, 3, 10, 23, 59)), isTrue);
    expect(isOnTime(date, DateTime.utc(2026, 3, 9)), isTrue);
    expect(isOnTime(date, DateTime.utc(2026, 3, 11)), isFalse);
  });

  test('isResponsesFilled requires every question answered', () {
    expect(isResponsesFilled(answers({'0': 'a'}), content), isFalse);
    expect(isResponsesFilled(answers({'0': 'a', '1': ''}), content), isFalse);
    expect(isResponsesFilled(answers({'0': 'a', '1': 'b'}), content), isTrue);
  });

  test('isResponseEmpty ignores blank answers', () {
    expect(isResponseEmpty(const Responses()), isTrue);
    expect(isResponseEmpty(answers({'0': ''})), isTrue);
    expect(isResponseEmpty(answers({'0': 'x'})), isFalse);
  });

  test('Responses.without drops empty bodies', () {
    final r = answers({'0': 'a'}).without('1', '0');
    expect(r.isEmpty, isTrue);
  });

  test('responseThumbnailLocation follows the resize extension layout', () {
    expect(
      responseThumbnailLocation('gs://b/responses/u1/photo.jpg', 'u1'),
      'gs://b/responses/u1/thumbs/photo_200x200.jpg',
    );
  });
}
