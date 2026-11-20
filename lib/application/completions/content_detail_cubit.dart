import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/audio/entities.dart';
import '../../domain/authentication/session.dart';
import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/analytics.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/common/media_upload.dart';
import '../../domain/completions/entities.dart';
import '../../domain/completions/interfaces.dart';
import '../../domain/completions/policies.dart';
import '../common/app_events.dart';
import '../common/load_status.dart';

/// One-shot UI effects of the content detail screen.
enum ContentDetailEffect {
  /// "No responses found" dialog.
  noResponses,

  /// "Response(s) Saved as Draft" dialog.
  savedAsDraft,

  /// "Uploading Image in Progress" dialog (exit blocked).
  uploadInProgress,

  /// Error toast with [ContentDetailState.actionError].
  actionError,
}

/// A scripture passage of the content, loaded from the Bible API.
class PassageLoad extends Equatable {
  const PassageLoad.loading()
      : status = LoadStatus.loading,
        passage = null;

  const PassageLoad.loaded(BiblePassage this.passage)
      : status = LoadStatus.success;

  const PassageLoad.failed()
      : status = LoadStatus.failure,
        passage = null;

  final LoadStatus status;

  /// Set when [status] is success.
  final BiblePassage? passage;

  @override
  List<Object?> get props => [status, passage];
}

class ContentDetailState extends Equatable {
  const ContentDetailState({
    this.status = LoadStatus.initial,
    this.content,
    this.series,
    this.errorMessage,
    this.completionId = '',
    this.isComplete,
    this.responses = const Responses(),
    this.imageUrls = const {},
    this.thumbnailUrls = const {},
    this.localImages = const {},
    this.uploads = const {},
    this.passages = const {},
    this.actionError,
    this.effect,
    this.effectId = 0,
  });

  final LoadStatus status;
  final SeriesContent? content;

  /// The series of the content, loaded only when it has audio (its title and
  /// image are shown on the lock screen). `null` until loaded or if it fails.
  final BibleSeries? series;
  final String? errorMessage;

  /// Id of the completion document ('' when there is none).
  final String completionId;

  /// `null` until known; `false` for drafts.
  final bool? isComplete;
  final Responses responses;

  /// Body index -> download URLs of uploaded response images.
  final Map<String, List<String>> imageUrls;

  /// Body index -> thumbnail URLs (only for images loaded from the server).
  final Map<String, List<String>> thumbnailUrls;

  /// Body index -> images picked in this session (shown until reload).
  final Map<String, List<ImageData>> localImages;

  /// Body index -> running upload.
  final Map<String, UploadHandle> uploads;

  /// Passage id -> passage of the scripture bodies. Loaded after the content
  /// so a slow Bible API never delays the rest of the screen.
  final Map<String, PassageLoad> passages;

  final String? actionError;
  final ContentDetailEffect? effect;
  final int effectId;

  bool get isUploading => uploads.isNotEmpty;

  ContentDetailState copyWith({
    LoadStatus? status,
    SeriesContent? content,
    BibleSeries? series,
    String? errorMessage,
    String? completionId,
    bool? isComplete,
    Responses? responses,
    Map<String, List<String>>? imageUrls,
    Map<String, List<String>>? thumbnailUrls,
    Map<String, List<ImageData>>? localImages,
    Map<String, UploadHandle>? uploads,
    Map<String, PassageLoad>? passages,
    String? actionError,
    ContentDetailEffect? effect,
    int? effectId,
  }) {
    return ContentDetailState(
      status: status ?? this.status,
      content: content ?? this.content,
      series: series ?? this.series,
      errorMessage: errorMessage ?? this.errorMessage,
      completionId: completionId ?? this.completionId,
      isComplete: isComplete ?? this.isComplete,
      responses: responses ?? this.responses,
      imageUrls: imageUrls ?? this.imageUrls,
      thumbnailUrls: thumbnailUrls ?? this.thumbnailUrls,
      localImages: localImages ?? this.localImages,
      uploads: uploads ?? this.uploads,
      passages: passages ?? this.passages,
      actionError: actionError ?? this.actionError,
      effect: effect ?? this.effect,
      effectId: effectId ?? this.effectId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        content,
        series,
        errorMessage,
        completionId,
        isComplete,
        responses,
        imageUrls,
        thumbnailUrls,
        localImages,
        uploads.keys.toList(),
        passages,
        actionError,
        effect,
        effectId,
      ];
}

/// State holder of the series content detail screen: content, scripture
/// passages, completion, question responses and image responses.
///
/// Completion data written to Firestore is identical to the pre-refactor app.
class ContentDetailCubit extends Cubit<ContentDetailState> {
  ContentDetailCubit({
    required this.bibleSeriesId,
    required this.contentId,
    required IBibleSeriesRepository bibleSeriesRepository,
    required IBiblePassageRepository biblePassageRepository,
    required ICompletionsRepository completionsRepository,
    required IAnalytics analytics,
    required AppEventBus events,
    required ISession session,
    DateTime Function()? clock,
  })  : _bibleSeries = bibleSeriesRepository,
        _passages = biblePassageRepository,
        _completions = completionsRepository,
        _analytics = analytics,
        _events = events,
        _session = session,
        _clock = clock ?? DateTime.now,
        super(const ContentDetailState());

  final String bibleSeriesId;
  final String contentId;
  final IBibleSeriesRepository _bibleSeries;
  final IBiblePassageRepository _passages;
  final ICompletionsRepository _completions;
  final IAnalytics _analytics;
  final AppEventBus _events;
  final ISession _session;
  final DateTime Function() _clock;

  /// The in-flight or completed series request; cleared on failure so the
  /// next caller retries.
  Future<BibleSeries>? _seriesRequest;

  void _safeEmit(ContentDetailState s) {
    if (!isClosed) emit(s);
  }

  void _notifyChanged() => _events.emit(
        CompletionChanged(seriesId: bibleSeriesId, contentId: contentId),
      );

  void _fail(Object e, StackTrace stackTrace) => _safeEmit(state.copyWith(
        actionError: userMessageFor(e, stackTrace: stackTrace),
        effect: ContentDetailEffect.actionError,
        effectId: nextEffectId(),
      ));

  void _effect(ContentDetailEffect effect) =>
      _safeEmit(state.copyWith(effect: effect, effectId: nextEffectId()));

  Future<void> load() async {
    unawaited(_analytics.log(AnalyticsEvents.engagementViewed));
    try {
      final results = await Future.wait([
        _bibleSeries.getContentDetails(
          bibleSeriesId: bibleSeriesId,
          seriesContentId: contentId,
        ),
        _completions.getCompletionOrNull(seriesContentId: contentId),
      ]);
      final content = results[0] as SeriesContent;
      final completion = results[1] as CompletionDetails?;
      final passageIds = {
        for (final body in content.body)
          if (body is ScriptureBody) ...body.passageIds,
      };
      var next = state.copyWith(
        status: LoadStatus.success,
        content: content,
        completionId: completion?.id ?? '',
        isComplete: completion != null && !completion.isDraft,
        passages: {
          for (final id in passageIds) id: const PassageLoad.loading(),
        },
      );
      final hasResponseBodies = content.body.any((b) =>
          b.type == SeriesContentBodyType.question ||
          b.type == SeriesContentBodyType.imageInput);
      if (hasResponseBodies && completion != null) {
        next = await _withLoadedResponses(next, completion.id);
      }
      _safeEmit(next);
      for (final id in passageIds) {
        unawaited(_loadPassage(id));
      }
      if (content.body.any((b) => b is AudioBody)) unawaited(_loadSeries());
    } catch (e, stackTrace) {
      _safeEmit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: userMessageFor(e, stackTrace: stackTrace),
      ));
    }
  }

  /// Reloads a passage that failed to load.
  Future<void> retryPassage(String passageId) async {
    if (state.passages[passageId]?.status != LoadStatus.failure) return;
    _safeEmit(state.copyWith(passages: {
      ...state.passages,
      passageId: const PassageLoad.loading(),
    }));
    await _loadPassage(passageId);
  }

  /// The series (fetched once): its Bible id is needed to load passages and
  /// its title and image enrich audio tracks.
  Future<BibleSeries> _series() => _seriesRequest ??= _bibleSeries
          .getBibleSeriesDetails(bibleSeriesId: bibleSeriesId)
          .then((series) {
        _safeEmit(state.copyWith(series: series));
        return series;
      }).catchError((Object e, StackTrace st) {
        _seriesRequest = null;
        Error.throwWithStackTrace(e, st);
      });

  Future<void> _loadPassage(String passageId) async {
    PassageLoad result;
    try {
      final series = await _series();
      result = PassageLoad.loaded(await _passages.getPassage(
        bibleId: series.scriptureBibleId,
        passageId: passageId,
      ));
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      result = const PassageLoad.failed();
    }
    _safeEmit(state.copyWith(passages: {...state.passages, passageId: result}));
  }

  /// Best-effort: without the series, audio still plays (no artwork).
  Future<void> _loadSeries() async {
    try {
      await _series();
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
    }
  }

  /// The player track of the audio body at [bodyIndex]: titled by the body
  /// (or the content), with the content and series as subtitle, the series
  /// image as artwork, and this content as origin.
  AudioTrack audioTrackFor(int bodyIndex, AudioBody body) {
    final content = state.content;
    final contentTitle = content?.title ?? '';
    final title = body.title.trim().isNotEmpty ? body.title : contentTitle;
    final subtitle = [
      if (contentTitle.isNotEmpty && contentTitle != title) contentTitle,
      if (state.series != null) state.series!.title,
    ].join(' · ');
    return AudioTrack(
      id: '$contentId/$bodyIndex',
      url: body.audioFileUrl,
      title: title.isNotEmpty ? title : 'Audio',
      subtitle: subtitle.isEmpty ? null : subtitle,
      artworkUrl: state.series?.imageUrl,
      origin: AudioTrackOrigin(
        seriesId: bibleSeriesId,
        contentId: contentId,
        contentType: content?.contentType,
      ),
    );
  }

  Future<ContentDetailState> _withLoadedResponses(
    ContentDetailState s,
    String completionId,
  ) async {
    final responses =
        await _completions.getResponses(completionId: completionId);
    final userId = _session.currentUser?.id;
    final imageUrls = <String, List<String>>{};
    final thumbnailUrls = <String, List<String>>{};
    for (final body in responses.responses.entries) {
      for (final answer in body.value.values) {
        if (answer.type != ResponseType.image || userId == null) continue;
        final thumb = responseThumbnailLocation(answer.response, userId);
        final urls = await Future.wait([
          _completions.getDownloadUrl(gsUrl: thumb),
          _completions.getDownloadUrl(gsUrl: answer.response),
        ]);
        thumbnailUrls[body.key] = [urls[0]];
        imageUrls[body.key] = [urls[1]];
      }
    }
    return s.copyWith(
      responses: responses,
      imageUrls: imageUrls,
      thumbnailUrls: thumbnailUrls,
    );
  }

  CompletionDetails _details({required bool isDraft}) {
    final now = _clock();
    return CompletionDetails(
      id: state.completionId,
      seriesId: bibleSeriesId,
      contentId: state.content!.id,
      isDraft: isDraft,
      isOnTime: isOnTime(state.content!.date, now),
      completionDate: now,
    );
  }

  /// Text answer changed. Editing a completed content makes it incomplete.
  void questionChanged(int bodyIndex, int questionIndex, String value) {
    final wasComplete = state.isComplete == true;
    final completionId = state.completionId;
    _safeEmit(state.copyWith(
      responses: state.responses.withResponse(
        '$bodyIndex',
        '$questionIndex',
        ResponseDetails(type: ResponseType.text, response: value),
      ),
    ));
    if (wasComplete) unawaited(_markIncomplete(completionId));
  }

  /// The complete button was tapped.
  Future<void> complete() async {
    final content = state.content;
    if (content == null || state.isComplete == true) return;
    if (content.isResponsePossible) {
      if (state.responses.isEmpty) {
        _effect(ContentDetailEffect.noResponses);
        return;
      }
      if (!isResponsesFilled(state.responses, content)) {
        _effect(ContentDetailEffect.savedAsDraft);
        await _saveDraft();
        return;
      }
    }
    await _markComplete();
  }

  /// The (green) completed button was tapped.
  Future<void> undoComplete() => _markIncomplete(state.completionId);

  Future<void> _markComplete() async {
    try {
      final details = _details(isDraft: false);
      final id = state.completionId.isEmpty
          ? await _completions.markAsComplete(completionDetails: details)
          : await _completions.updateComplete(
              completionDetails: details,
              completionId: state.completionId,
            );
      unawaited(_analytics.log(AnalyticsEvents.engagementCompleted));
      final responseId = await _completions.putResponses(
        completionId: id,
        responses: state.responses,
      );
      _safeEmit(state.copyWith(
        isComplete: true,
        completionId: id,
        responses: state.responses.withId(responseId),
      ));
      _notifyChanged();
    } catch (e, stackTrace) {
      _fail(e, stackTrace);
    }
  }

  Future<void> _saveDraft() async {
    if (state.isComplete != false) return;
    try {
      var id = state.completionId;
      if (id.isEmpty) {
        id = await _completions.markAsComplete(
          completionDetails: _details(isDraft: true),
        );
      }
      final responseId = await _completions.putResponses(
        completionId: id,
        responses: state.responses,
      );
      _safeEmit(state.copyWith(
        isComplete: false,
        completionId: id,
        responses: state.responses.withId(responseId),
      ));
      _notifyChanged();
    } catch (e, stackTrace) {
      _fail(e, stackTrace);
    }
  }

  Future<void> _markIncomplete(String completionId) async {
    try {
      await _completions.markAsIncomplete(
        completionId: completionId,
        isResponsePossible: !state.responses.isEmpty,
      );
      _safeEmit(state.copyWith(isComplete: false, completionId: ''));
      _notifyChanged();
    } catch (e, stackTrace) {
      _fail(e, stackTrace);
    }
  }

  /// Back navigation requested. Returns `false` (and shows a dialog) while an
  /// image upload is in progress; otherwise saves a draft (or removes an
  /// empty completion) and returns `true`.
  bool requestExit() {
    if (state.isUploading) {
      _effect(ContentDetailEffect.uploadInProgress);
      return false;
    }
    final content = state.content;
    if (content != null && content.isResponsePossible) {
      if (!isResponseEmpty(state.responses)) {
        unawaited(_saveDraft());
      } else if (state.completionId.isNotEmpty) {
        unawaited(_markIncomplete(state.completionId));
      }
    }
    return true;
  }

  /// Uploads a response image for the image-input body at [bodyIndex].
  /// Uploading makes a completed content incomplete.
  Future<void> uploadImage(int bodyIndex, ImageData image) async {
    final key = '$bodyIndex';
    try {
      final handle = _completions.uploadImage(image: image);
      _safeEmit(state.copyWith(uploads: {key: handle}));
      final location = await handle.location;
      final url = await _completions.getDownloadUrl(gsUrl: location);

      final urls = [...?state.imageUrls[key], url];
      if (state.completionId.isNotEmpty) {
        await _completions.markAsIncomplete(
          completionId: state.completionId,
          isResponsePossible: true,
        );
      }
      _safeEmit(state.copyWith(
        responses: state.responses.withResponse(
          key,
          '${urls.length - 1}',
          ResponseDetails(type: ResponseType.image, response: location),
        ),
        imageUrls: {...state.imageUrls, key: urls},
        localImages: {
          ...state.localImages,
          key: [...?state.localImages[key], image],
        },
        uploads: const {},
        completionId: '',
        isComplete: false,
      ));
      _notifyChanged();
    } catch (e, stackTrace) {
      _safeEmit(state.copyWith(uploads: const {}));
      _fail(e, stackTrace);
    }
  }

  /// Removes the response image of the body at [bodyIndex].
  Future<void> deleteImage(int bodyIndex) async {
    final key = '$bodyIndex';
    final gsUrl = state.responses.responses[key]?['0']?.response;
    if (gsUrl == null) return;
    try {
      final userId = _session.requireUser().id;
      unawaited(_completions.deleteImage(gsUrl: gsUrl).catchError((_) {}));
      unawaited(_completions
          .deleteImage(gsUrl: responseThumbnailLocation(gsUrl, userId))
          .catchError((_) {}));

      final remaining = (state.imageUrls[key]?.length ?? 1) - 1;
      var responses = state.responses.without(key, '$remaining');
      if (responses.isEmpty) responses = const Responses();

      if (state.completionId.isNotEmpty) {
        await _completions.markAsIncomplete(
          completionId: state.completionId,
          isResponsePossible: true,
        );
      }
      _safeEmit(state.copyWith(
        responses: responses,
        imageUrls: Map.of(state.imageUrls)..remove(key),
        thumbnailUrls: Map.of(state.thumbnailUrls)..remove(key),
        localImages: Map.of(state.localImages)..remove(key),
        completionId: '',
        isComplete: false,
      ));
      _notifyChanged();
    } catch (e, stackTrace) {
      _fail(e, stackTrace);
    }
  }
}
