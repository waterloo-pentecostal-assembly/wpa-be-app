import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/exceptions.dart';
import '../../domain/bible_series/interfaces.dart';
import '../common/firestore_data.dart';

/// Returns the signed-in user's Firebase ID token (`null` when signed out).
/// [forceRefresh] fetches a new token even if the cached one looks valid.
typedef IdTokenProvider = Future<String?> Function(bool forceRefresh);

/// [IBiblePassageRepository] backed by the WPA Bible API proxy
/// (`GET /v1/bibles/{bibleId}/passages/{passageId}?content-type=text`),
/// authenticated with the user's Firebase ID token.
///
/// Passages never change, so successful responses are kept in memory for the
/// life of the app; concurrent requests for the same passage share one call.
class BibleApiRepository implements IBiblePassageRepository {
  BibleApiRepository({
    required http.Client client,
    required IdTokenProvider idToken,
    Uri? baseUrl,
    this.bibleId = defaultBibleId,
    this.timeout = const Duration(seconds: 60),
  })  : _client = client,
        _idToken = idToken,
        _baseUrl = baseUrl ?? defaultBaseUrl;

  static final Uri defaultBaseUrl =
      Uri.parse('https://wpa-be-bible-proxy.onrender.com/');

  /// The Bible version shown in the app.
  static const String defaultBibleId = '78a9f6124f344018-01';

  final http.Client _client;
  final IdTokenProvider _idToken;
  final Uri _baseUrl;
  final String bibleId;

  /// Generous: the proxy may need to cold start.
  final Duration timeout;

  final Map<String, Future<BiblePassage>> _passages = {};

  @override
  Future<BiblePassage> getPassage(String passageId) => _passages.putIfAbsent(
        passageId,
        () => _fetch(passageId).catchError((Object e, StackTrace st) {
          _passages.remove(passageId); // retry on the next call
          Error.throwWithStackTrace(e, st);
        }),
      );

  Uri passageUri(String passageId) => _baseUrl.resolveUri(Uri(
        pathSegments: ['v1', 'bibles', bibleId, 'passages', passageId],
        queryParameters: {'content-type': 'text'},
      ));

  Future<BiblePassage> _fetch(String passageId) async {
    final uri = passageUri(passageId);
    var response = await _get(uri, forceRefresh: false);
    if (response.statusCode == 401) {
      // The cached token may have just expired.
      response = await _get(uri, forceRefresh: true);
    }
    if (response.statusCode != 200) {
      throw BibleSeriesException(
        code: BibleSeriesExceptionCode.passageUnavailable,
        message: 'Unable to load scripture',
        details: 'GET $uri -> ${response.statusCode}: ${response.body}',
      );
    }
    return parseBiblePassage(
      passageId,
      jsonDecode(utf8.decode(response.bodyBytes)),
    );
  }

  Future<http.Response> _get(Uri uri, {required bool forceRefresh}) async {
    final token = await _idToken(forceRefresh);
    if (token == null) {
      throw BibleSeriesException(
        code: BibleSeriesExceptionCode.passageUnavailable,
        message: 'Unable to load scripture',
        details: 'GET $uri: no signed-in user',
      );
    }
    return _client.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    }).timeout(timeout);
  }
}

/// Parses a passage response: `{"data": {"id", "reference", "content",
/// "copyright"}}` (the bare `data` object is accepted too).
BiblePassage parseBiblePassage(String passageId, Object? json) {
  if (json is! Map) {
    throw BibleSeriesException(
      code: BibleSeriesExceptionCode.passageUnavailable,
      message: 'Unable to load scripture',
      details: 'Passage $passageId: unexpected response $json',
    );
  }
  final root = Map<String, dynamic>.from(json);
  final data = root['data'] is Map
      ? Map<String, dynamic>.from(root['data'] as Map)
      : root;
  return BiblePassage(
    id: data.optional('id', passageId),
    reference: data.optional('reference', passageId),
    content: data.require<String>('content'),
    copyright: data.optional('copyright', ''),
  );
}
