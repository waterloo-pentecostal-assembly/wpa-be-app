import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/bible_series/exceptions.dart';
import 'package:wpa_app/infrastructure/bible_series/bible_api_repository.dart';

const _bibleId = 'de4e12af7f28f599-02';
const _passageId = '1KI.2.1-1KI.2.3';
const _content = ' [1] Now the days of David drew nigh that he should die; and '
    'he charged Solomon his son, saying, [2] I go the way of all the earth: be '
    'thou strong therefore, and shew thyself a man; [3] And keep the charge of '
    'the LORD thy God, to walk in his ways \n';
const _copyright = 'PUBLIC DOMAIN except in the United Kingdom, where a Crown '
    'Copyright applies to printing the KJV.';

/// Shape of a real proxy response.
Map<String, dynamic> _body() => {
      'data': {
        'id': _passageId,
        'orgId': _passageId,
        'bibleId': _bibleId,
        'bookId': '1KI',
        'chapterIds': ['1KI.2'],
        'reference': '1 Kings 2:1-3',
        'content': _content,
        'verseCount': 3,
        'copyright': _copyright,
      },
      'meta': {'fumsToken': 'G08BYIzTFfOihHUPgtpW6pvPPDSG0CDxIto6LF19151eD4j'},
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
    respond = (_) => _json(_body());
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

  test('requests the text passage with the ID token and parses it', () async {
    final passage = await get(build());

    expect(
      passage,
      const BiblePassage(
        id: _passageId,
        reference: '1 Kings 2:1-3',
        content: _content,
        copyright: _copyright,
      ),
    );
    final request = requests.single;
    expect(request.method, 'GET');
    expect(
      request.url.toString(),
      'https://wpa-be-bible-proxy.onrender.com/v1/bibles/de4e12af7f28f599-02'
      '/passages/1KI.2.1-1KI.2.3?content-type=text',
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

    expect(
        requests.map((r) => r.url.pathSegments[2]), [_bibleId, 'other-bible']);
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

    expect(passage.reference, '1 Kings 2:1-3');
    expect(requests, hasLength(2));
  });

  test('an error response throws and is not cached', () async {
    respond = (_) => _json({'message': 'Not found'}, 404);
    final repository = build();

    await expectLater(
      get(repository),
      throwsA(isA<BibleSeriesException>().having(
        (e) => e.code,
        'code',
        BibleSeriesExceptionCode.passageUnavailable,
      )),
    );

    respond = (_) => _json(_body());
    expect((await get(repository)).id, _passageId);
    expect(requests, hasLength(2));
  });

  test('signed out: throws without calling the API', () async {
    token = null;
    await expectLater(
      get(build()),
      throwsA(isA<BibleSeriesException>()),
    );
    expect(requests, isEmpty);
    expect(tokenRefreshes, [false]);
  });

  test('accepts a bare data object', () {
    final passage = parseBiblePassage(_passageId, {'content': '[1] Text'});
    expect(passage.id, _passageId);
    expect(passage.reference, _passageId);
    expect(passage.copyright, '');
  });
}
