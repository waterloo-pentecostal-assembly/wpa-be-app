import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wpa_app/domain/bible/entities.dart';
import 'package:wpa_app/domain/bible/exceptions.dart';
import 'package:wpa_app/infrastructure/bible/bible_api_parsing.dart';
import 'package:wpa_app/infrastructure/bible/bible_api_repository.dart';

const _bibleId = 'de4e12af7f28f599-02';
const _passageId = 'JHN.3.16-JHN.3.17';
const _copyright = 'PUBLIC DOMAIN except in the United Kingdom.';

Map<String, dynamic> _text(String text, [String? verseId]) => {
      'text': text,
      'type': 'text',
      if (verseId != null)
        'attrs': {
          'verseId': verseId,
          'verseOrgIds': [verseId],
        },
    };

Map<String, dynamic> _verse(String number, String sid) => {
      'name': 'verse',
      'type': 'tag',
      'attrs': {'number': number, 'style': 'v', 'sid': sid},
      'items': [_text(number)],
    };

Map<String, dynamic> _para(String style, List<Object> items) => {
      'name': 'para',
      'type': 'tag',
      'attrs': {'style': style},
      'items': items,
    };

/// `content-type=json` content of John 3:16-17 with a heading, a red-letter
/// span (`wj`), a footnote and a poetry line.
final List<Object> _content = [
  _para('s1', [_text('God so loved')]),
  _para('p', [
    _verse('16', 'JHN 3:16'),
    {
      'name': 'char',
      'type': 'tag',
      'attrs': {'style': 'wj'},
      'items': [_text('For God so loved the world, ', 'JHN.3.16')],
    },
    {
      'name': 'note',
      'type': 'tag',
      'attrs': {'style': 'f'},
      'items': [_text('a footnote', 'JHN.3.16')],
    },
    _text('that he gave. ', 'JHN.3.16'),
  ]),
  _para('q1', [
    _verse('17', 'JHN 3:17'),
    _text('For God sent not his Son. ', 'JHN.3.17'),
  ]),
  _para('b', []),
];

/// Shape of a real proxy response.
Map<String, dynamic> _body() => {
      'data': {
        'id': _passageId,
        'orgId': _passageId,
        'bibleId': _bibleId,
        'bookId': 'JHN',
        'chapterIds': ['JHN.3'],
        'reference': 'John 3:16-17',
        'content': _content,
        'verseCount': 2,
        'copyright': _copyright,
      },
      'meta': {'fumsToken': 'token'},
    };

Map<String, dynamic> _bibles() => {
      'data': [
        {
          'id': 'de4e12af7f28f599-02',
          'dblId': 'de4e12af7f28f599',
          'abbreviation': 'engKJV',
          'abbreviationLocal': 'KJV',
          'language': {
            'id': 'eng',
            'name': 'English',
            'nameLocal': 'English',
            'script': 'Latin',
            'scriptDirection': 'LTR',
          },
          'countries': [],
          'name': 'King James (Authorised) Version',
          'nameLocal': 'King James Version',
          'description': 'Protestant',
          'type': 'text',
          'audioBibles': [],
        },
        {'name': 'no id'},
        {
          'id': 'b',
          'abbreviation': 'RVR',
          'name': '',
          'nameLocal': 'Reina Valera',
        },
      ],
    };

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  late List<http.Request> requests;
  late List<bool> tokenRefreshes;
  late http.Response Function(http.Request) respond;
  String? token;

  setUp(() {
    requests = [];
    tokenRefreshes = [];
    token = 'token-1';
    respond = (request) => request.url.pathSegments.contains('passages')
        ? _json(_body())
        : _json(_bibles());
  });

  BibleApiRepository build() => BibleApiRepository(
        client: MockClient((request) async {
          requests.add(request);
          return respond(request);
        }),
        idToken: (forceRefresh) async {
          tokenRefreshes.add(forceRefresh);
          return token;
        },
      );

  Future<BiblePassage> get(BibleApiRepository repository,
          {String bibleId = _bibleId}) =>
      repository.getPassage(bibleId: bibleId, passageId: _passageId);

  group('passages', () {
    test('requests the JSON passage with the ID token and parses it', () async {
      final passage = await get(build());

      expect(
        passage,
        const BiblePassage(
          id: _passageId,
          bibleId: _bibleId,
          reference: 'John 3:16-17',
          copyright: _copyright,
          blocks: [
            PassageHeading('God so loved'),
            PassageParagraph([
              VerseSegment(
                text: '16',
                verseId: 'JHN.3.16',
                isVerseNumber: true,
              ),
              VerseSegment(
                text: 'For God so loved the world, ',
                verseId: 'JHN.3.16',
              ),
              VerseSegment(text: 'that he gave. ', verseId: 'JHN.3.16'),
            ]),
            PassageParagraph(
              [
                VerseSegment(
                  text: '17',
                  verseId: 'JHN.3.17',
                  isVerseNumber: true,
                ),
                VerseSegment(
                  text: 'For God sent not his Son. ',
                  verseId: 'JHN.3.17',
                ),
              ],
              isIndented: true,
            ),
          ],
        ),
      );
      expect(passage.verseIds, ['JHN.3.16', 'JHN.3.17']);
      expect(
        passage.verseText('JHN.3.16'),
        'For God so loved the world, that he gave.',
      );
      final request = requests.single;
      expect(request.method, 'GET');
      expect(
        request.url.toString(),
        'https://wpa-be-bible-proxy.onrender.com/v1/bibles/de4e12af7f28f599-02'
        '/passages/JHN.3.16-JHN.3.17?content-type=json&include-notes=false'
        '&include-titles=true&include-verse-numbers=true',
      );
      expect(request.headers['Authorization'], 'Bearer token-1');
    });

    test('caches passages and shares concurrent requests', () async {
      final repository = build();
      final results = await Future.wait([get(repository), get(repository)]);
      await get(repository);

      expect(results[0], results[1]);
      expect(requests, hasLength(1));
    });

    test('caches the same passage of different Bibles separately', () async {
      final repository = build();
      await get(repository);
      await get(repository, bibleId: 'other-bible');

      expect(requests.map((r) => r.url.pathSegments[2]),
          [_bibleId, 'other-bible']);
    });

    test('retries once with a refreshed token on 401', () async {
      respond = (request) => request.headers['Authorization'] == 'Bearer fresh'
          ? _json(_body())
          : _json({'message': 'Invalid or expired ID token.'}, 401);
      final repository = BibleApiRepository(
        client: MockClient((request) async {
          requests.add(request);
          return respond(request);
        }),
        idToken: (forceRefresh) async => forceRefresh ? 'fresh' : 'stale',
      );

      final passage = await get(repository);

      expect(passage.reference, 'John 3:16-17');
      expect(requests, hasLength(2));
    });

    test('an error response throws and is not cached', () async {
      respond = (_) => _json({'message': 'Not found'}, 404);
      final repository = build();

      await expectLater(
        get(repository),
        throwsA(isA<BibleException>().having(
          (e) => e.code,
          'code',
          BibleExceptionCode.passageUnavailable,
        )),
      );

      respond = (_) => _json(_body());
      expect((await get(repository)).id, _passageId);
      expect(requests, hasLength(2));
    });

    test('signed out: throws without calling the API', () async {
      token = null;
      await expectLater(get(build()), throwsA(isA<BibleException>()));
      expect(requests, isEmpty);
      expect(tokenRefreshes, [false]);
    });
  });

  group('versions', () {
    test('lists the Bibles once, skipping entries without an id', () async {
      final repository = build();
      final versions = await repository.getBibles();
      await repository.getBibles();

      expect(versions, const [
        BibleVersion(
          id: 'de4e12af7f28f599-02',
          name: 'King James (Authorised) Version',
          abbreviation: 'KJV',
          description: 'Protestant',
          languageId: 'eng',
          languageName: 'English',
        ),
        BibleVersion(id: 'b', name: 'Reina Valera', abbreviation: 'RVR'),
      ]);
      expect(requests.single.url.toString(),
          'https://wpa-be-bible-proxy.onrender.com/v1/bibles');
      expect(requests.single.headers['Authorization'], 'Bearer token-1');
    });

    test('a failure throws and the next call retries', () async {
      respond = (_) => _json({'message': 'down'}, 503);
      final repository = build();
      await expectLater(
        repository.getBibles(),
        throwsA(isA<BibleException>().having(
          (e) => e.code,
          'code',
          BibleExceptionCode.versionsUnavailable,
        )),
      );

      respond = (_) => _json(_bibles());
      expect(await repository.getBibles(), hasLength(2));
      expect(requests, hasLength(2));
    });
  });

  group('parsing', () {
    test('accepts a bare data object', () {
      final passage = parseBiblePassage(
        bibleId: _bibleId,
        passageId: _passageId,
        json: {'content': _content},
      );
      expect(passage.id, _passageId);
      expect(passage.bibleId, _bibleId);
      expect(passage.reference, _passageId);
      expect(passage.copyright, '');
    });

    test('a verse number without text keeps the id from its sid', () {
      final blocks = parsePassageContent([
        _para('p', [
          _verse('37', 'ACT 8:37'),
          _verse('38', 'ACT 8:38'),
          _text('And he commanded the chariot', 'ACT.8.38'),
        ]),
      ]);
      final segments = (blocks.single as PassageParagraph).segments;
      expect(
          segments.map((s) => s.verseId), ['ACT.8.37', 'ACT.8.38', 'ACT.8.38']);
    });

    test('falls back to plain text, inferring verse ids across chapters', () {
      final passage = parseBiblePassage(
        bibleId: _bibleId,
        passageId: 'JHN.3.36-JHN.4.1',
        json: {
          'data': {
            'reference': 'John 3:36-4:1',
            'content': 'Heading\n     [36] He that believeth. \n'
                '[1] When therefore the Lord knew\n',
          },
        },
      );
      expect(passage.blocks.first, const PassageHeading('Heading'));
      expect(passage.verseIds, ['JHN.3.36', 'JHN.4.1']);
      expect(passage.verseText('JHN.4.1'), 'When therefore the Lord knew');
    });

    test('an unexpected response throws', () {
      expect(
        () => parseBiblePassage(
            bibleId: _bibleId, passageId: _passageId, json: [1]),
        throwsA(isA<BibleException>()),
      );
      expect(() => parseBibleVersions({'data': 'x'}),
          throwsA(isA<BibleException>()));
    });
  });
}
