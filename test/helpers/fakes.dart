/// Hand-written fakes and test-data builders shared by application,
/// presentation and widget tests.
///
/// Every fake repository records the methods called in [FakeCalls.calls] and
/// can be told to fail a method with [FakeCalls.failOn]. Failing methods
/// throw (asynchronously for `Future` methods) the configured error.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:wpa_app/domain/achievements/entities.dart';
import 'package:wpa_app/domain/achievements/interfaces.dart';
import 'package:wpa_app/domain/audio/entities.dart';
import 'package:wpa_app/domain/audio/exceptions.dart';
import 'package:wpa_app/domain/audio/interfaces.dart';
import 'package:wpa_app/domain/admin/interfaces.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/authentication/interfaces.dart';
import 'package:wpa_app/domain/authentication/session.dart';
import 'package:wpa_app/domain/authentication/value_objects.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/bible_series/exceptions.dart';
import 'package:wpa_app/domain/bible_series/interfaces.dart';
import 'package:wpa_app/domain/common/analytics.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/common/media_upload.dart';
import 'package:wpa_app/domain/common/paging.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/domain/completions/interfaces.dart';
import 'package:wpa_app/domain/forum/entities.dart';
import 'package:wpa_app/domain/forum/interfaces.dart';
import 'package:wpa_app/domain/links/entities.dart';
import 'package:wpa_app/domain/links/interface.dart';
import 'package:wpa_app/domain/media/entities.dart';
import 'package:wpa_app/domain/media/interfaces.dart';
import 'package:wpa_app/domain/notification_settings/entities.dart';
import 'package:wpa_app/domain/notification_settings/interfaces.dart';
import 'package:wpa_app/domain/prayer_requests/entities.dart';
import 'package:wpa_app/domain/prayer_requests/interfaces.dart';
import 'package:wpa_app/domain/testimonies/entities.dart';
import 'package:wpa_app/domain/testimonies/interfaces.dart';
import 'package:wpa_app/domain/user_profile/entities.dart';
import 'package:wpa_app/domain/user_profile/interfaces.dart';

// ---------------------------------------------------------------------------
// Infrastructure helpers
// ---------------------------------------------------------------------------

/// Default error thrown by failing fakes. Its message is user-safe.
const kFakeError = ApplicationException(
  code: ApplicationExceptionCode.unknown,
  message: 'Fake failure',
);

/// Call recording and failure injection shared by the fakes.
mixin FakeCalls {
  /// Names of the methods called, in order.
  final List<String> calls = [];
  final Map<String, Object> _failures = {};

  /// Makes [method] throw [error] until [succeedOn] is called.
  void failOn(String method, [Object error = kFakeError]) =>
      _failures[method] = error;

  void succeedOn(String method) => _failures.remove(method);

  int callCount(String method) => calls.where((c) => c == method).length;

  /// Records [method] and throws when it was configured to fail.
  void record(String method) {
    calls.add(method);
    final error = _failures[method];
    if (error != null) throw error;
  }
}

// ---------------------------------------------------------------------------
// Session & analytics
// ---------------------------------------------------------------------------

class FakeSession implements ISession {
  FakeSession([LocalUser? user]) : _user = user;

  LocalUser? _user;
  final _controller = StreamController<LocalUser?>.broadcast(sync: true);

  @override
  LocalUser? get currentUser => _user;

  /// Sets the user and notifies [changes] listeners synchronously.
  set user(LocalUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Stream<LocalUser?> get changes => _controller.stream;

  Future<void> dispose() => _controller.close();
}

class LoggedEvent {
  const LoggedEvent(this.name, this.params);
  final String name;
  final Map<String, Object>? params;

  @override
  String toString() => 'LoggedEvent($name, $params)';
}

class FakeAnalytics implements IAnalytics {
  final List<LoggedEvent> events = [];

  List<String> get names => events.map((e) => e.name).toList();

  @override
  Future<void> log(String name, [Map<String, Object>? params]) async {
    events.add(LoggedEvent(name, params));
  }
}

// ---------------------------------------------------------------------------
// Uploads
// ---------------------------------------------------------------------------

/// Upload controlled by the test: push progress with [emitProgress] and end it
/// with [finish] or [fail].
class FakeUploadHandle implements UploadHandle {
  final _progress = StreamController<UploadProgress>.broadcast();
  final _location = Completer<String>();

  @override
  Stream<UploadProgress> get progress => _progress.stream;

  @override
  Future<String> get location => _location.future;

  void emitProgress(int transferred, int total) => _progress
      .add(UploadProgress(bytesTransferred: transferred, totalBytes: total));

  void finish(String location) {
    _location.complete(location);
    _progress.close();
  }

  void fail([Object error = kFakeError]) {
    _location.completeError(error);
    _progress.close();
  }
}

ImageData buildImage([String fileName = 'photo.jpg']) =>
    ImageData(bytes: Uint8List.fromList([1, 2, 3]), fileName: fileName);

// ---------------------------------------------------------------------------
// Test data builders
// ---------------------------------------------------------------------------

LocalUser buildUser({
  String id = 'user-1',
  String firstName = 'Jane',
  String lastName = 'Doe',
  bool isAdmin = false,
  String? profilePhotoUrl,
  String? profilePhoto,
}) =>
    LocalUser(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: '$id@example.com',
      reports: 0,
      thumbnailUrl: null,
      thumbnail: null,
      profilePhotoUrl: profilePhotoUrl,
      profilePhoto: profilePhoto,
      isAdmin: isAdmin,
      isVerified: true,
    );

const kSnippet = UserSnippet(
  firstName: 'Jane',
  lastName: 'Doe',
  thumbnailUrl: null,
  thumbnail: null,
);

PrayerRequest buildPrayerRequest(
  String id, {
  String request = 'Please pray',
  bool isMine = false,
  bool isAnswered = false,
  bool hasPrayed = false,
  bool isApproved = true,
  bool isAnonymous = false,
}) =>
    PrayerRequest(
      id: id,
      userId: isMine ? 'user-1' : 'other',
      request: request,
      prayedBy: const [],
      reportedBy: const [],
      hasPrayed: hasPrayed,
      hasReported: false,
      isMine: isMine,
      isApproved: isApproved,
      date: DateTime(2026, 1, 1),
      isAnonymous: isAnonymous,
      userSnippet: kSnippet,
      isAnswered: isAnswered,
    );

Testimony buildTestimony(
  String id, {
  String request = 'Praise report',
  bool isMine = false,
  bool isArchived = false,
  bool hasPraised = false,
  bool isApproved = true,
  bool isAnonymous = false,
}) =>
    Testimony(
      id: id,
      userId: isMine ? 'user-1' : 'other',
      request: request,
      praisedBy: const [],
      reportedBy: const [],
      hasPraised: hasPraised,
      hasReported: false,
      isMine: isMine,
      isApproved: isApproved,
      date: DateTime(2026, 1, 1),
      isAnonymous: isAnonymous,
      userSnippet: kSnippet,
      isArchived: isArchived,
    );

/// A series with one day per entry of [days]; day `i` holds the contents
/// `day{i}-read` (READ) and `day{i}-reflect` (REFLECT).
BibleSeries buildSeries({
  String id = 'series-1',
  required List<DateTime> days,
  bool isActive = true,
}) =>
    BibleSeries(
      id: id,
      title: 'Series $id',
      subTitle: 'Sub',
      imageUrl: 'https://img/$id',
      imageGsLocation: 'gs://img/$id',
      startDate: days.isEmpty ? DateTime(2026) : days.first,
      endDate: days.isEmpty ? DateTime(2026) : days.last,
      isActive: isActive,
      isVisible: true,
      scriptureBibleId: 'bible-$id',
      seriesContentSnippet: [
        for (var i = 0; i < days.length; i++)
          SeriesContentSnippet(
            date: days[i],
            availableContentTypes: [
              AvailableContentType(
                  seriesContentType: 'READ', contentId: 'day$i-read'),
              AvailableContentType(
                  seriesContentType: 'REFLECT', contentId: 'day$i-reflect'),
            ],
          ),
      ],
    );

CompletionDetails buildCompletion(
  String contentId, {
  String? id,
  String seriesId = 'series-1',
  bool isDraft = false,
  bool isOnTime = true,
}) =>
    CompletionDetails(
      id: id ?? 'completion-$contentId',
      seriesId: seriesId,
      contentId: contentId,
      isOnTime: isOnTime,
      isDraft: isDraft,
      completionDate: DateTime(2026, 1, 1),
    );

ForumThread buildThread({
  String id = 'thread-1',
  String forumId = 'forum-1',
  String authorId = 'user-1',
  required DateTime createdAt,
  bool isFrozen = false,
  bool isHidden = false,
}) =>
    ForumThread(
      id: id,
      forumId: forumId,
      title: 'Thread $id',
      authorId: authorId,
      authorName: 'Jane Doe',
      createdAt: createdAt,
      updatedAt: createdAt,
      commentCount: 0,
      isFrozen: isFrozen,
      isHidden: isHidden,
    );

Comment buildComment(
  String id, {
  String threadId = 'thread-1',
  String authorId = 'user-1',
  required DateTime createdAt,
  String? parentId,
  bool isDeleted = false,
  List<String> likedBy = const [],
}) =>
    Comment(
      id: id,
      threadId: threadId,
      body: 'Comment $id',
      authorId: authorId,
      authorName: 'Jane Doe',
      createdAt: createdAt,
      updatedAt: createdAt,
      parentId: parentId,
      isHidden: false,
      isDeleted: isDeleted,
      likedBy: likedBy,
      reportCount: 0,
    );

NotificationSettingsEntity buildNotificationSettings({
  bool enabled = true,
  List<String> threadsFollowed = const [],
}) =>
    NotificationSettingsEntity(
      id: 'settings-1',
      dailyEngagementReminder: enabled,
      prayers: enabled,
      newPrayerRequest: enabled,
      testimonies: enabled,
      newTestimony: enabled,
      newForumThread: enabled,
      forumCommentReplies: enabled,
      forumThreadComments: enabled,
      forumCommentLikes: enabled,
      threadsFollowed: threadsFollowed,
    );

// ---------------------------------------------------------------------------
// Authentication
// ---------------------------------------------------------------------------

class FakeAuthenticationFacade with FakeCalls implements IAuthenticationFacade {
  FakeAuthenticationFacade({this.session, LocalUser? user})
      : user = user ?? buildUser();

  /// When set, sign-in / sign-out / deletion update this session like the
  /// real facade does.
  final FakeSession? session;

  /// User returned by sign-in and [getSignedInUser].
  LocalUser user;
  bool deviceTokenExistsResult = true;

  EmailAddress? lastEmail;
  Password? lastPassword;
  Name? lastFirstName;
  Name? lastLastName;
  String? lastDeletedUserId;
  String? lastDeviceTokenUserId;

  @override
  Future<bool> deviceTokenExists(String userId) async {
    record('deviceTokenExists');
    return deviceTokenExistsResult;
  }

  @override
  Future<void> addDeviceToken(String userId) async {
    record('addDeviceToken');
    lastDeviceTokenUserId = userId;
  }

  @override
  Future<LocalUser> getSignedInUser() async {
    record('getSignedInUser');
    session?.user = user;
    return user;
  }

  @override
  Future<void> registerWithEmailAndPassword({
    required Name firstName,
    required Name lastName,
    required EmailAddress emailAddress,
    required Password password,
  }) async {
    lastFirstName = firstName;
    lastLastName = lastName;
    lastEmail = emailAddress;
    lastPassword = password;
    record('registerWithEmailAndPassword');
  }

  @override
  Future<LocalUser> signInWithEmailAndPassword({
    required EmailAddress emailAddress,
    required Password password,
  }) async {
    lastEmail = emailAddress;
    lastPassword = password;
    record('signInWithEmailAndPassword');
    session?.user = user;
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(
      {required EmailAddress emailAddress}) async {
    lastEmail = emailAddress;
    record('sendPasswordResetEmail');
  }

  @override
  Future<void> sendAccountVerificationEmail({
    required EmailAddress emailAddress,
    required Password password,
  }) async {
    record('sendAccountVerificationEmail');
  }

  @override
  Future<void> signOut() async {
    record('signOut');
    if (session?.currentUser != null) session?.user = null;
  }

  @override
  Future<void> initiateDelete(String userId) async {
    lastDeletedUserId = userId;
    record('initiateDelete');
    if (session?.currentUser != null) session?.user = null;
  }
}

// ---------------------------------------------------------------------------
// Bible series, achievements, media, completions
// ---------------------------------------------------------------------------

class FakeBibleSeriesRepository
    with FakeCalls
    implements IBibleSeriesRepository {
  final Map<String, BibleSeries> seriesById = {};

  /// Returned by [getBibleSeries] (truncated to `limit`).
  List<BibleSeries> seriesList = [];
  bool hasActive = false;

  /// Keyed by content id.
  final Map<String, SeriesContent> contents = {};

  int? lastLimit;
  bool? lastIsActive;

  @override
  Future<BibleSeries> getBibleSeriesDetails(
      {required String bibleSeriesId}) async {
    record('getBibleSeriesDetails');
    final series = seriesById[bibleSeriesId];
    if (series == null) {
      throw const BibleSeriesException(
        code: BibleSeriesExceptionCode.noBibleSeries,
        message: 'Bible series not found',
      );
    }
    return series;
  }

  @override
  Future<bool> hasActiveBibleSeries() async {
    record('hasActiveBibleSeries');
    return hasActive;
  }

  @override
  Future<SeriesContent> getContentDetails({
    required String bibleSeriesId,
    required String seriesContentId,
  }) async {
    record('getContentDetails');
    final content = contents[seriesContentId];
    if (content == null) {
      throw const BibleSeriesException(
        code: BibleSeriesExceptionCode.noSeriesContent,
        message: 'Content not found',
      );
    }
    return content;
  }

  @override
  Future<List<BibleSeries>> getBibleSeries({
    required int limit,
    bool isActive = false,
  }) async {
    lastLimit = limit;
    lastIsActive = isActive;
    record('getBibleSeries');
    return seriesList.take(limit).toList();
  }
}

class FakeBiblePassageRepository
    with FakeCalls
    implements IBiblePassageRepository {
  /// Keyed by passage id.
  final Map<String, BiblePassage> passages = {};

  /// The `bibleId` of every [getPassage] call, in order.
  final List<String> bibleIds = [];

  @override
  Future<BiblePassage> getPassage({
    required String bibleId,
    required String passageId,
  }) async {
    record('getPassage');
    bibleIds.add(bibleId);
    final passage = passages[passageId];
    if (passage == null) {
      throw BibleSeriesException(
        code: BibleSeriesExceptionCode.passageUnavailable,
        message: 'Unable to load scripture',
        details: '$passageId not found',
      );
    }
    return passage;
  }
}

class FakeAchievementsRepository
    with FakeCalls
    implements IAchievementsRepository {
  final controller = StreamController<Achievements>.broadcast();
  Achievements achievements = const Achievements(seriesProgress: 0);

  @override
  Future<Achievements> getAchievements() async {
    record('getAchievements');
    return achievements;
  }

  @override
  Stream<Achievements> watchAchievements() {
    record('watchAchievements');
    return controller.stream;
  }
}

class FakeMediaRepository with FakeCalls implements IMediaRepository {
  List<Media> media = [];

  @override
  Future<List<Media>> getAvailableMedia() async {
    record('getAvailableMedia');
    return media;
  }
}

/// In-memory completions store of the signed-in user.
class FakeCompletionsRepository
    with FakeCalls
    implements ICompletionsRepository {
  /// Keyed by content id.
  final Map<String, CompletionDetails> completions = {};

  /// Keyed by completion id.
  final Map<String, Responses> responses = {};

  /// Upload returned by the next [uploadImage] call.
  FakeUploadHandle nextUpload = FakeUploadHandle();
  final List<String> deletedImages = [];
  final List<({String completionId, bool isResponsePossible})> incompleted = [];
  int _nextId = 1;

  CompletionDetails? completionById(String id) =>
      completions.values.where((c) => c.id == id).firstOrNull;

  @override
  Future<Map<String, CompletionDetails>> getAllCompletions(
      {required String bibleSeriesId}) async {
    record('getAllCompletions');
    return {
      for (final e in completions.entries)
        if (e.value.seriesId == bibleSeriesId) e.key: e.value,
    };
  }

  @override
  Future<CompletionDetails?> getCompletionOrNull(
      {required String seriesContentId}) async {
    record('getCompletionOrNull');
    return completions[seriesContentId];
  }

  @override
  Future<Responses> getResponses({required String completionId}) async {
    record('getResponses');
    return responses[completionId] ?? const Responses();
  }

  @override
  Future<String> putResponses({
    required String completionId,
    required Responses responses,
  }) async {
    record('putResponses');
    final id = responses.id ?? 'response-$completionId';
    this.responses[completionId] = responses.withId(id);
    return id;
  }

  @override
  Future<String> markAsComplete(
      {required CompletionDetails completionDetails}) async {
    record('markAsComplete');
    final id = 'completion-${_nextId++}';
    completions[completionDetails.contentId] = _withId(completionDetails, id);
    return id;
  }

  @override
  Future<void> markAsIncomplete({
    required String completionId,
    required bool isResponsePossible,
  }) async {
    incompleted.add((
      completionId: completionId,
      isResponsePossible: isResponsePossible,
    ));
    record('markAsIncomplete');
    completions.removeWhere((_, c) => c.id == completionId);
    if (isResponsePossible) responses.remove(completionId);
  }

  @override
  Future<String> updateComplete({
    required CompletionDetails completionDetails,
    required String completionId,
  }) async {
    record('updateComplete');
    completions[completionDetails.contentId] =
        _withId(completionDetails, completionId);
    return completionId;
  }

  @override
  UploadHandle uploadImage({required ImageData image}) {
    record('uploadImage');
    return nextUpload;
  }

  @override
  Future<void> deleteImage({required String gsUrl}) async {
    deletedImages.add(gsUrl);
    record('deleteImage');
  }

  @override
  Future<String> getDownloadUrl({required String gsUrl}) async {
    record('getDownloadUrl');
    return 'https://download/$gsUrl';
  }

  static CompletionDetails _withId(CompletionDetails d, String id) =>
      CompletionDetails(
        id: id,
        seriesId: d.seriesId,
        contentId: d.contentId,
        isOnTime: d.isOnTime,
        isDraft: d.isDraft,
        completionDate: d.completionDate,
      );
}

// ---------------------------------------------------------------------------
// Prayer requests & testimonies
// ---------------------------------------------------------------------------

/// Offset-based cursor used by the fake paginated repositories.
class FakeCursor extends PageCursor {
  const FakeCursor(this.offset);
  final int offset;
}

PageResult<T> _page<T>(List<T> all, int limit, PageCursor? after) {
  final start = after is FakeCursor ? after.offset : 0;
  final end = (start + limit).clamp(0, all.length);
  final items = all.sublist(start.clamp(0, all.length), end);
  return PageResult(
    items: items,
    nextCursor: end < all.length ? FakeCursor(end) : null,
  );
}

class FakePrayerRequestsRepository
    with FakeCalls
    implements IPrayerRequestsRepository {
  /// Approved open posts served page by page by [getPrayerRequests].
  List<PrayerRequest> all = [];
  List<PrayerRequest> mine = [];
  List<PrayerRequest> answered = [];
  bool canAdd = true;

  /// Cursors received by [getPrayerRequests], in order.
  final List<PageCursor?> requestedCursors = [];
  final List<String> deletedIds = [];
  final List<String> reportedIds = [];
  final List<String> prayedIds = [];
  final List<String> closedIds = [];
  ({String request, bool isAnonymous})? lastCreated;

  @override
  Future<PageResult<PrayerRequest>> getPrayerRequests(
      {required int limit, PageCursor? after}) async {
    requestedCursors.add(after);
    record('getPrayerRequests');
    return _page(all, limit, after);
  }

  @override
  Future<List<PrayerRequest>> getMyPrayerRequests() async {
    record('getMyPrayerRequests');
    return mine;
  }

  @override
  Future<List<PrayerRequest>> getMyAnsweredPrayerRequests() async {
    record('getMyAnsweredPrayerRequests');
    return answered;
  }

  @override
  Future<bool> canAddPrayerRequest() async {
    record('canAddPrayerRequest');
    return canAdd;
  }

  @override
  Future<void> deletePrayerRequest({required String id}) async {
    record('deletePrayerRequest');
    deletedIds.add(id);
  }

  @override
  Future<PrayerRequest> closePrayerRequest({required String id}) async {
    record('closePrayerRequest');
    closedIds.add(id);
    return buildPrayerRequest(id, isMine: true, isAnswered: true);
  }

  @override
  Future<void> reportPrayerRequest({required String id}) async {
    record('reportPrayerRequest');
    reportedIds.add(id);
  }

  @override
  Future<void> prayForPrayerRequest({required String id}) async {
    record('prayForPrayerRequest');
    prayedIds.add(id);
  }

  @override
  Future<PrayerRequest> createPrayerRequest(
      {required String request, required bool isAnonymous}) async {
    record('createPrayerRequest');
    lastCreated = (request: request, isAnonymous: isAnonymous);
    return buildPrayerRequest(
      'new-prayer',
      request: request,
      isMine: true,
      isApproved: false,
      isAnonymous: isAnonymous,
    );
  }
}

class FakeTestimoniesRepository
    with FakeCalls
    implements ITestimoniesRepository {
  List<Testimony> all = [];
  List<Testimony> mine = [];
  List<Testimony> archived = [];
  bool canAdd = true;

  final List<PageCursor?> requestedCursors = [];
  final List<String> deletedIds = [];
  final List<String> reportedIds = [];
  final List<String> praisedIds = [];
  final List<String> closedIds = [];
  ({String request, bool isAnonymous})? lastCreated;

  @override
  Future<PageResult<Testimony>> getTestimonies(
      {required int limit, PageCursor? after}) async {
    requestedCursors.add(after);
    record('getTestimonies');
    return _page(all, limit, after);
  }

  @override
  Future<List<Testimony>> getMyTestimonies() async {
    record('getMyTestimonies');
    return mine;
  }

  @override
  Future<List<Testimony>> getMyArchivedTestimonies() async {
    record('getMyArchivedTestimonies');
    return archived;
  }

  @override
  Future<bool> canAddTestimony() async {
    record('canAddTestimony');
    return canAdd;
  }

  @override
  Future<void> deleteTestimony({required String id}) async {
    record('deleteTestimony');
    deletedIds.add(id);
  }

  @override
  Future<Testimony> closeTestimony({required String id}) async {
    record('closeTestimony');
    closedIds.add(id);
    return buildTestimony(id, isMine: true, isArchived: true);
  }

  @override
  Future<void> reportTestimony({required String id}) async {
    record('reportTestimony');
    reportedIds.add(id);
  }

  @override
  Future<void> praiseTestimony({required String id}) async {
    record('praiseTestimony');
    praisedIds.add(id);
  }

  @override
  Future<Testimony> createTestimony(
      {required String request, required bool isAnonymous}) async {
    record('createTestimony');
    lastCreated = (request: request, isAnonymous: isAnonymous);
    return buildTestimony(
      'new-testimony',
      request: request,
      isMine: true,
      isApproved: false,
      isAnonymous: isAnonymous,
    );
  }
}

// ---------------------------------------------------------------------------
// Forum & notification settings
// ---------------------------------------------------------------------------

/// Forum fake whose streams are pushed by the test through the controllers.
class FakeForumRepository with FakeCalls implements IForumRepository {
  final forum = StreamController<Forum>.broadcast();
  final threads = StreamController<List<ForumThread>>.broadcast();
  final thread = StreamController<ForumThread?>.broadcast();
  final comments = StreamController<List<Comment>>.broadcast();

  String createdThreadId = 'thread-new';
  final List<NewThread> createdThreads = [];
  final List<NewComment> addedComments = [];
  final List<({String id, String body})> updatedComments = [];
  final List<String> likedIds = [];
  final List<String> unlikedIds = [];
  final List<String> deletedCommentIds = [];
  final List<String> reportedCommentIds = [];
  final List<bool> hiddenValues = [];
  final List<bool> frozenValues = [];
  final List<String> updatedTitles = [];
  bool? lastWatchThreadsIsAdmin;

  @override
  Stream<Forum> watchForum(String forumId) {
    record('watchForum');
    return forum.stream;
  }

  @override
  Stream<List<ForumThread>> watchThreads(String forumId,
      {bool isAdmin = false}) {
    lastWatchThreadsIsAdmin = isAdmin;
    record('watchThreads');
    return threads.stream;
  }

  @override
  Stream<ForumThread?> watchThread(String threadId, String forumId) {
    record('watchThread');
    return thread.stream;
  }

  @override
  Future<String> createThread(NewThread thread) async {
    record('createThread');
    createdThreads.add(thread);
    return createdThreadId;
  }

  @override
  Future<void> freezeThread(
      String threadId, String forumId, bool isFrozen) async {
    record('freezeThread');
    frozenValues.add(isFrozen);
  }

  @override
  Future<void> hideThread(
      String threadId, String forumId, bool isHidden) async {
    record('hideThread');
    hiddenValues.add(isHidden);
  }

  @override
  Future<void> updateThread(
      String threadId, String forumId, String newTitle) async {
    record('updateThread');
    updatedTitles.add(newTitle);
  }

  @override
  Stream<List<Comment>> watchComments(String threadId, String forumId) {
    record('watchComments');
    return comments.stream;
  }

  @override
  Future<void> addComment(NewComment comment, String forumId) async {
    record('addComment');
    addedComments.add(comment);
  }

  @override
  Future<void> deleteComment(
      String commentId, String threadId, String forumId) async {
    record('deleteComment');
    deletedCommentIds.add(commentId);
  }

  @override
  Future<void> reportComment(
    String commentId,
    String threadId,
    String forumId,
    String reason,
  ) async {
    record('reportComment');
    reportedCommentIds.add(commentId);
  }

  @override
  Future<void> likeComment(
    String commentId,
    String threadId,
    String forumId,
    String userId,
  ) async {
    record('likeComment');
    likedIds.add(commentId);
  }

  @override
  Future<void> unlikeComment(
    String commentId,
    String threadId,
    String forumId,
    String userId,
  ) async {
    record('unlikeComment');
    unlikedIds.add(commentId);
  }

  @override
  Future<void> updateComment(
    String commentId,
    String threadId,
    String forumId,
    String newBody,
  ) async {
    record('updateComment');
    updatedComments.add((id: commentId, body: newBody));
  }

  Future<void> dispose() async {
    await forum.close();
    await threads.close();
    await thread.close();
    await comments.close();
  }
}

class FakeNotificationSettingsService
    with FakeCalls
    implements INotificationSettingsService {
  FakeNotificationSettingsService([NotificationSettingsEntity? settings])
      : settings = settings ?? buildNotificationSettings();

  NotificationSettingsEntity settings;
  final List<({NotificationSetting setting, bool enabled})> setCalls = [];
  final List<String> followed = [];
  final List<String> unfollowed = [];

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() async {
    record('getNotificationSettings');
    return settings;
  }

  @override
  Future<void> setSetting(NotificationSetting setting, bool enabled) async {
    setCalls.add((setting: setting, enabled: enabled));
    record('setSetting');
    settings = settings.withSetting(setting, enabled);
  }

  @override
  Future<void> followThread(String threadId) async {
    record('followThread');
    followed.add(threadId);
  }

  @override
  Future<void> unfollowThread(String threadId) async {
    record('unfollowThread');
    unfollowed.add(threadId);
  }
}

// ---------------------------------------------------------------------------
// Admin, profile, links
// ---------------------------------------------------------------------------

class FakeAdminService with FakeCalls implements IAdminService {
  List<LocalUser> unverifiedUsers = [];
  List<PrayerRequest> unapprovedPrayerRequests = [];
  List<Testimony> unapprovedTestimonies = [];

  /// `method:id` for every mutating call.
  final List<String> actions = [];

  Future<void> _act(String method, String id) async {
    actions.add('$method:$id');
    record(method);
  }

  @override
  Future<void> verifyUser({required String userId}) =>
      _act('verifyUser', userId);

  @override
  Future<List<LocalUser>> getUnverifiedUsers() async {
    record('getUnverifiedUsers');
    return unverifiedUsers;
  }

  @override
  Future<void> deleteUnverifiedUsers({required String userId}) =>
      _act('deleteUnverifiedUsers', userId);

  @override
  Future<void> approvePrayerRequest({required String prayerRequestId}) =>
      _act('approvePrayerRequest', prayerRequestId);

  @override
  Future<void> deletePrayerRequest({required String prayerRequestId}) =>
      _act('deletePrayerRequest', prayerRequestId);

  @override
  Future<List<PrayerRequest>> getUnapprovedPrayerRequest() async {
    record('getUnapprovedPrayerRequest');
    return unapprovedPrayerRequests;
  }

  @override
  Future<void> approveTestimony({required String testimonyId}) =>
      _act('approveTestimony', testimonyId);

  @override
  Future<void> deleteTestimony({required String testimonyId}) =>
      _act('deleteTestimony', testimonyId);

  @override
  Future<List<Testimony>> getUnapprovedTestimonies() async {
    record('getUnapprovedTestimonies');
    return unapprovedTestimonies;
  }
}

class FakeUserProfileRepository
    with FakeCalls
    implements IUserProfileRepository {
  FakeUserProfileRepository(this.session);

  final FakeSession session;
  FakeUploadHandle nextUpload = FakeUploadHandle();
  ({String profilePhoto, String thumbnail})? lastSetPhoto;

  @override
  Future<LocalUser> refreshCurrentUser() async {
    record('refreshCurrentUser');
    final current = session.requireUser();
    final photo = lastSetPhoto;
    final refreshed = photo == null
        ? current
        : buildUser(
            id: current.id,
            firstName: current.firstName,
            lastName: current.lastName,
            isAdmin: current.isAdmin,
            profilePhoto: photo.profilePhoto,
            profilePhotoUrl: 'https://download/${photo.profilePhoto}',
          );
    session.user = refreshed;
    return refreshed;
  }

  @override
  UploadHandle uploadProfilePhoto(ImageData image) {
    record('uploadProfilePhoto');
    return nextUpload;
  }

  @override
  Future<void> setProfilePhoto({
    required String profilePhoto,
    required String thumbnail,
  }) async {
    record('setProfilePhoto');
    lastSetPhoto = (profilePhoto: profilePhoto, thumbnail: thumbnail);
  }

  /// User ids passed to [updateLastActive], in order.
  final List<String> lastActiveUpdates = [];

  @override
  Future<void> updateLastActive(String userId) async {
    record('updateLastActive');
    lastActiveUpdates.add(userId);
  }
}

class FakeLinksRepository with FakeCalls implements ILinksRepository {
  AppLinks links = const AppLinks();

  @override
  Future<AppLinks> getLinks() async {
    record('getLinks');
    return links;
  }
}

// ---------------------------------------------------------------------------
// Audio
// ---------------------------------------------------------------------------

class FakeAudioPlayer with FakeCalls implements IAudioPlayer {
  FakeAudioPlayer({this.trackDuration = const Duration(minutes: 3)});

  /// Duration reported for every loaded track.
  Duration trackDuration;

  final _playback = StreamController<AudioPlayback>.broadcast(sync: true);
  final _position = StreamController<Duration>.broadcast(sync: true);

  @override
  AudioPlayback playback = const AudioPlayback();

  @override
  Duration position = Duration.zero;

  final List<AudioTrack> loaded = [];
  final List<Duration> seeks = [];

  @override
  Stream<AudioPlayback> get playbackStream => _playback.stream;

  @override
  Stream<Duration> get positionStream => _position.stream;

  /// Emits a new snapshot (as the real player does on every change).
  void emit(AudioPlayback next) {
    playback = next;
    _playback.add(next);
  }

  void emitPosition(Duration next) {
    position = next;
    _position.add(next);
  }

  AudioPlayback _with({
    AudioTrack? track,
    AudioProcessing? processing,
    bool? playing,
    double? speed,
    String? errorMessage,
  }) =>
      AudioPlayback(
        track: track ?? playback.track,
        processing: processing ?? playback.processing,
        playing: playing ?? playback.playing,
        duration: playback.duration,
        bufferedPosition: playback.bufferedPosition,
        speed: speed ?? playback.speed,
        errorMessage: errorMessage,
      );

  /// Like the real player: the track becomes current at once; a failure
  /// (see [failOn]) marks it failed and throws.
  @override
  Future<void> load(AudioTrack track) async {
    loaded.add(track);
    emitPosition(Duration.zero);
    emit(AudioPlayback(
      track: track,
      processing: AudioProcessing.loading,
      speed: playback.speed,
    ));
    try {
      record('load');
    } catch (_) {
      emit(AudioPlayback(
        track: track,
        speed: playback.speed,
        errorMessage: kAudioPlaybackErrorMessage,
      ));
      rethrow;
    }
    emit(AudioPlayback(
      track: track,
      processing: AudioProcessing.ready,
      duration: trackDuration,
      speed: playback.speed,
    ));
  }

  @override
  Future<void> play() async {
    record('play');
    emit(_with(playing: true));
  }

  @override
  Future<void> pause() async {
    record('pause');
    emit(_with(playing: false));
  }

  @override
  Future<void> seek(Duration position) async {
    record('seek');
    seeks.add(position);
    emitPosition(position);
  }

  @override
  Future<void> skipBackward() async => record('skipBackward');

  @override
  Future<void> skipForward() async => record('skipForward');

  @override
  Future<void> setSpeed(double speed) async {
    record('setSpeed');
    emit(_with(speed: speed));
  }

  @override
  Future<void> stop() async {
    record('stop');
    emitPosition(Duration.zero);
    emit(const AudioPlayback());
  }
}
