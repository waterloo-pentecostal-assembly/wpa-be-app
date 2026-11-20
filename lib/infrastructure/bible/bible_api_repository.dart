import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/bible/entities.dart';
import '../../domain/bible/exceptions.dart';
import '../../domain/bible/interfaces.dart';
import 'bible_api_parsing.dart';

/// Returns the signed-in user's Firebase ID token (`null` when signed out).
/// [forceRefresh] fetches a new token even if the cached one looks valid.
typedef IdTokenProvider = Future<String?> Function(bool forceRefresh);

/// [IBiblePassageRepository] and [IBibleVersionRepository] backed by the WPA
/// Bible API proxy, authenticated with the user's Firebase ID token:
/// - `GET /v1/bibles` lists the versions;
/// - `GET /v1/bibles/{bibleId}/passages/{passageId}?content-type=json` reads
///   a passage, with verse ids on every piece of verse text.
///
/// Passages and the version list don't change while the app runs, so
/// successful responses are kept in memory; concurrent requests for the same
/// resource share one call. Failures are not cached.
class BibleApiRepository
    implements IBiblePassageRepository, IBibleVersionRepository {
  BibleApiRepository({
    required http.Client client,
    required IdTokenProvider idToken,
    Uri? baseUrl,
    this.timeout = const Duration(seconds: 60),
  })  : _client = client,
        _idToken = idToken,
        _baseUrl = baseUrl ?? defaultBaseUrl;

  static final Uri defaultBaseUrl =
      Uri.parse('https://wpa-be-bible-proxy.onrender.com/');

  final http.Client _client;
  final IdTokenProvider _idToken;
  final Uri _baseUrl;

  /// Generous: the proxy may need to cold start.
  final Duration timeout;

  /// Keyed by `bibleId/passageId`.
  final Map<String, Future<BiblePassage>> _passages = {};
  Future<List<BibleVersion>>? _versions;

  @override
  Future<BiblePassage> getPassage({
    required String bibleId,
    required String passageId,
  }) {
    final key = '$bibleId/$passageId';
    return _passages.putIfAbsent(
      key,
      () => _fetchPassage(bibleId, passageId)
          .catchError((Object e, StackTrace st) {
        _passages.remove(key); // retry on the next call
        Error.throwWithStackTrace(e, st);
      }),
    );
  }

  @override
  Future<List<BibleVersion>> getBibles() =>
      _versions ??= _fetchVersions().catchError((Object e, StackTrace st) {
        _versions = null; // retry on the next call
        Error.throwWithStackTrace(e, st);
      });

  Uri passageUri({required String bibleId, required String passageId}) =>
      _baseUrl.resolveUri(Uri(
        pathSegments: ['v1', 'bibles', bibleId, 'passages', passageId],
        queryParameters: {
          'content-type': 'json',
          'include-notes': 'false',
          'include-titles': 'true',
          'include-verse-numbers': 'true',
        },
      ));

  Uri get biblesUri => _baseUrl.resolveUri(Uri(pathSegments: ['v1', 'bibles']));

  Future<BiblePassage> _fetchPassage(String bibleId, String passageId) async {
    final json = await _getJson(
      passageUri(bibleId: bibleId, passageId: passageId),
      code: BibleExceptionCode.passageUnavailable,
      message: 'Unable to load scripture',
    );
    return parseBiblePassage(
      bibleId: bibleId,
      passageId: passageId,
      json: json,
    );
  }

  Future<List<BibleVersion>> _fetchVersions() async {
    final json = await _getJson(
      biblesUri,
      code: BibleExceptionCode.versionsUnavailable,
      message: 'Unable to load Bible versions',
    );
    return parseBibleVersions(json);
  }

  Future<Object?> _getJson(
    Uri uri, {
    required BibleExceptionCode code,
    required String message,
  }) async {
    var response = await _get(uri, forceRefresh: false, code: code);
    if (response.statusCode == 401) {
      // The cached token may have just expired.
      response = await _get(uri, forceRefresh: true, code: code);
    }
    if (response.statusCode != 200) {
      throw BibleException(
        code: code,
        message: message,
        details: 'GET $uri -> ${response.statusCode}: ${response.body}',
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<http.Response> _get(
    Uri uri, {
    required bool forceRefresh,
    required BibleExceptionCode code,
  }) async {
    final token = await _idToken(forceRefresh);
    if (token == null) {
      throw BibleException(
        code: code,
        message: 'Sign in to read scripture',
        details: 'GET $uri: no signed-in user',
      );
    }
    return _client.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    }).timeout(timeout);
  }
}
