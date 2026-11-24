import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/bible/entities.dart';
import '../../domain/bible/interfaces.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/common/paging.dart';
import '../common/app_events.dart';
import '../common/load_status.dart';
import 'verse_texts.dart';

/// Which saved verses the profile's list shows.
enum BibleNotesFilter { all, withNotes }

/// The verses of a saved verse, read from the Bible API in the user's
/// version.
class SavedVerseTextLoad extends Equatable {
  const SavedVerseTextLoad.loading()
      : status = LoadStatus.loading,
        verses = const [],
        bibleId = null;

  const SavedVerseTextLoad.loaded(this.verses, {required String this.bibleId})
      : status = LoadStatus.success;

  const SavedVerseTextLoad.failed()
      : status = LoadStatus.failure,
        verses = const [],
        bibleId = null;

  final LoadStatus status;

  /// Set when [status] is success.
  final List<VerseText> verses;

  /// The version [verses] are in; set when [status] is success.
  final String? bibleId;

  /// `16 For God so loved… 17 For God sent…`
  String get text => joinVerses(verses);

  @override
  List<Object?> get props => [status, verses, bibleId];
}

const _unset = Object();

class BibleNotesState extends Equatable {
  const BibleNotesState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.isEndOfList = false,
    this.isLoadingMore = false,
    this.filter = BibleNotesFilter.all,
    this.texts = const {},
    this.preferredBibleId,
    this.versionsStatus = LoadStatus.initial,
    this.versions = const [],
    this.errorMessage,
    this.message,
    this.messageIsError = false,
    this.messageId = 0,
  });

  final LoadStatus status;

  /// Loaded saved verses, newest first.
  final List<SavedVerse> items;
  final bool isEndOfList;
  final bool isLoadingMore;
  final BibleNotesFilter filter;

  /// Saved verse id -> its verses, loaded when it is opened.
  final Map<String, SavedVerseTextLoad> texts;

  /// The version the user chose (`users/{uid}.preferred_bible_id`); `null`
  /// shows each saved verse in its series' version.
  final String? preferredBibleId;

  /// Available versions (sorted by language, then name), loaded when a
  /// saved verse is first opened.
  final LoadStatus versionsStatus;
  final List<BibleVersion> versions;

  /// Abbreviation of [bibleId] (e.g. `KJV`), or '' while versions load.
  String abbreviationOf(String? bibleId) =>
      versions.where((v) => v.id == bibleId).firstOrNull?.abbreviation ?? '';

  /// Load failure (shown instead of the list).
  final String? errorMessage;

  /// One-shot toast ([messageId] changes for each one).
  final String? message;
  final bool messageIsError;
  final int messageId;

  /// [items] matching [filter].
  List<SavedVerse> get visibleItems => switch (filter) {
        BibleNotesFilter.all => items,
        BibleNotesFilter.withNotes => [
            for (final v in items)
              if (v.hasNote) v,
          ],
      };

  BibleNotesState copyWith({
    LoadStatus? status,
    List<SavedVerse>? items,
    bool? isEndOfList,
    bool? isLoadingMore,
    BibleNotesFilter? filter,
    Map<String, SavedVerseTextLoad>? texts,
    Object? preferredBibleId = _unset,
    LoadStatus? versionsStatus,
    List<BibleVersion>? versions,
    String? errorMessage,
    String? message,
    bool? messageIsError,
    int? messageId,
  }) {
    return BibleNotesState(
      status: status ?? this.status,
      items: items ?? this.items,
      isEndOfList: isEndOfList ?? this.isEndOfList,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filter: filter ?? this.filter,
      texts: texts ?? this.texts,
      preferredBibleId: identical(preferredBibleId, _unset)
          ? this.preferredBibleId
          : preferredBibleId as String?,
      versionsStatus: versionsStatus ?? this.versionsStatus,
      versions: versions ?? this.versions,
      errorMessage: errorMessage ?? this.errorMessage,
      message: message ?? this.message,
      messageIsError: messageIsError ?? this.messageIsError,
      messageId: messageId ?? this.messageId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        isEndOfList,
        isLoadingMore,
        filter,
        texts,
        preferredBibleId,
        versionsStatus,
        versions,
        errorMessage,
        message,
        messageIsError,
        messageId,
      ];
}

/// The profile's list of the user's saved verses (each with an optional
/// note): paged newest first, filterable, with note editing and removing.
/// The verses' text is read from the Bible API when one is opened
/// ([loadText]), in the user's version (`preferred_bible_id`, else the
/// series' version, like the reader). Stays in sync with the scripture reader through
/// [SavedVerseChanged] / [SavedVerseDeleted], and on the same version
/// through [PreferredBibleChanged].
class BibleNotesCubit extends Cubit<BibleNotesState> {
  BibleNotesCubit({
    required IBibleReaderRepository bibleReaderRepository,
    required IBiblePassageRepository biblePassageRepository,
    required IBibleSeriesRepository bibleSeriesRepository,
    required IBibleVersionRepository bibleVersionRepository,
    required AppEventBus events,
    this.pageSize = 30,
  })  : _reader = bibleReaderRepository,
        _passages = biblePassageRepository,
        _bibleSeries = bibleSeriesRepository,
        _versions = bibleVersionRepository,
        _events = events,
        super(const BibleNotesState()) {
    _subscriptions = [
      events.on<SavedVerseChanged>().listen((e) => _upsert(e.savedVerse)),
      events.on<SavedVerseDeleted>().listen((e) => _remove(e.id)),
      // A version chosen elsewhere (e.g. the reader).
      events.on<PreferredBibleChanged>().listen((e) {
        if (!_preferenceKnown || e.bibleId != state.preferredBibleId) {
          _useVersion(e.bibleId);
        }
      }),
    ];
  }

  final IBibleReaderRepository _reader;
  final IBiblePassageRepository _passages;
  final IBibleSeriesRepository _bibleSeries;
  final IBibleVersionRepository _versions;
  final AppEventBus _events;
  final int pageSize;
  late final List<StreamSubscription<AppEvent>> _subscriptions;
  PageCursor? _cursor;

  /// Whether [BibleNotesState.preferredBibleId] holds the user's choice
  /// (read from the repository, or chosen since).
  bool _preferenceKnown = false;

  /// Bumped on each version change, so texts still loading in the previous
  /// version are dropped.
  int _textGeneration = 0;

  void _safeEmit(BibleNotesState s) {
    if (!isClosed) emit(s);
  }

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }

  void _toast(String message, {bool isError = false}) =>
      _safeEmit(state.copyWith(
        message: message,
        messageIsError: isError,
        messageId: nextEffectId(),
      ));

  SavedVerse? _find(String id) =>
      state.items.where((v) => v.id == id).firstOrNull;

  /// Loads the first page.
  Future<void> load() async {
    _safeEmit(state.copyWith(status: LoadStatus.loading));
    try {
      final page = await _reader.getSavedVersesPage(limit: pageSize);
      _cursor = page.nextCursor;
      _safeEmit(state.copyWith(
        status: LoadStatus.success,
        items: page.items,
        isEndOfList: page.isEnd,
      ));
    } catch (e, stackTrace) {
      _safeEmit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: userMessageFor(e, stackTrace: stackTrace),
      ));
    }
  }

  /// Loads the next page (no-op at the end or while loading).
  Future<void> loadMore() async {
    if (!state.status.isSuccess ||
        state.isEndOfList ||
        state.isLoadingMore ||
        _cursor == null) {
      return;
    }
    _safeEmit(state.copyWith(isLoadingMore: true));
    try {
      final page =
          await _reader.getSavedVersesPage(limit: pageSize, after: _cursor);
      _cursor = page.nextCursor;
      final known = {for (final v in state.items) v.id};
      _safeEmit(state.copyWith(
        items: [
          ...state.items,
          for (final v in page.items)
            if (!known.contains(v.id)) v,
        ],
        isEndOfList: page.isEnd,
        isLoadingMore: false,
      ));
    } catch (e, stackTrace) {
      _safeEmit(state.copyWith(isLoadingMore: false));
      _toast(userMessageFor(e, stackTrace: stackTrace), isError: true);
    }
  }

  /// Loads the verses of [savedVerseId] in the user's version (no-op while
  /// loading or once loaded; retries after a failure).
  Future<void> loadText(String savedVerseId) async {
    final v = _find(savedVerseId);
    final current = state.texts[savedVerseId]?.status;
    if (v == null ||
        current == LoadStatus.loading ||
        current == LoadStatus.success) {
      return;
    }
    _setText(savedVerseId, const SavedVerseTextLoad.loading());
    unawaited(_loadVersions()); // for the version button
    final generation = _textGeneration;
    SavedVerseTextLoad result;
    try {
      final bibleId = await _bibleFor(v);
      result = SavedVerseTextLoad.loaded(
        await fetchVerseTexts(_passages,
            bibleId: bibleId, verseIds: v.verseIds),
        bibleId: bibleId,
      );
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      result = const SavedVerseTextLoad.failed();
    }
    // The version changed meanwhile: it is being reloaded in the new one.
    if (generation != _textGeneration) return;
    _setText(savedVerseId, result);
  }

  /// The version to show [v] in: the user's preferred version, else the
  /// version of the series it was saved from (as the reader does). A failed
  /// preference read is reported and falls back to the series.
  Future<String> _bibleFor(SavedVerse v) async {
    if (!_preferenceKnown) {
      try {
        final preferred = await _reader.getPreferredBibleId();
        if (!_preferenceKnown) {
          _preferenceKnown = true;
          _safeEmit(state.copyWith(preferredBibleId: preferred));
        }
      } catch (e, stackTrace) {
        reportError(e, stackTrace); // retried with the next text
      }
    }
    if (state.preferredBibleId case final preferred?) return preferred;
    final series =
        await _bibleSeries.getBibleSeriesDetails(bibleSeriesId: v.seriesId);
    return series.scriptureBibleId;
  }

  /// Loads the version list once (no-op while loading or once loaded).
  Future<void> _loadVersions() async {
    final status = state.versionsStatus;
    if (status == LoadStatus.loading || status == LoadStatus.success) return;
    _safeEmit(state.copyWith(versionsStatus: LoadStatus.loading));
    try {
      final versions = sortedByLanguage(await _versions.getBibles());
      _safeEmit(state.copyWith(
        versionsStatus: LoadStatus.success,
        versions: versions,
      ));
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      _safeEmit(state.copyWith(versionsStatus: LoadStatus.failure));
    }
  }

  /// Reloads the version list after a failure.
  Future<void> retryVersions() async {
    if (state.versionsStatus.isFailure) await _loadVersions();
  }

  /// Shows saved verses in [bibleId] from now on (`null`: each one in its
  /// series' version), here and in the reader, and saves it as the user's
  /// version. Opened saved verses reload in it.
  Future<void> selectBible(String? bibleId) async {
    if (_preferenceKnown && bibleId == state.preferredBibleId) return;
    _useVersion(bibleId);
    _events.emit(PreferredBibleChanged(bibleId));
    try {
      await _reader.setPreferredBibleId(bibleId);
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      _toast('Unable to save your Bible version', isError: true);
    }
  }

  /// Uses [bibleId] and reloads the texts loaded so far in it.
  void _useVersion(String? bibleId) {
    _preferenceKnown = true;
    _textGeneration++;
    final opened = state.texts.keys.toList();
    _safeEmit(state.copyWith(preferredBibleId: bibleId, texts: const {}));
    for (final id in opened) {
      unawaited(loadText(id));
    }
  }

  void _setText(String id, SavedVerseTextLoad load) =>
      _safeEmit(state.copyWith(texts: {...state.texts, id: load}));

  void setFilter(BibleNotesFilter filter) =>
      _safeEmit(state.copyWith(filter: filter));

  /// Adds, changes or (with `null` or blank) deletes the note of a saved
  /// verse. The verses stay saved. Returns whether it was saved.
  Future<bool> setNote(String savedVerseId, String? note) async {
    final text = note?.trim();
    final value = text == null || text.isEmpty ? null : text;
    final current = _find(savedVerseId);
    if (current == null) return false;
    try {
      await _reader.setNote(savedVerseId: savedVerseId, note: value);
      final updated = current.withNote(value);
      _upsert(updated);
      _events.emit(SavedVerseChanged(updated));
      _toast(value == null ? 'Note deleted' : 'Note saved');
      return true;
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      _toast(value == null ? 'Unable to delete note' : 'Unable to save note',
          isError: true);
      return false;
    }
  }

  /// Removes a saved verse, with its note. Returns whether it was removed.
  Future<bool> remove(String savedVerseId) async {
    if (_find(savedVerseId) == null) return false;
    try {
      await _reader.deleteSavedVerse(savedVerseId);
      _remove(savedVerseId);
      _events.emit(SavedVerseDeleted(savedVerseId));
      _toast('Removed from saved');
      return true;
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      _toast('Unable to remove verse', isError: true);
      return false;
    }
  }

  /// Replaces [v] in place, or (new) adds it at the top.
  void _upsert(SavedVerse v) {
    if (!state.status.isSuccess) return;
    final items = [...state.items];
    final index = items.indexWhere((x) => x.id == v.id);
    if (index < 0) {
      items.insert(0, v);
    } else {
      items[index] = v;
    }
    _safeEmit(state.copyWith(items: items));
  }

  void _remove(String id) {
    if (!state.items.any((v) => v.id == id)) return;
    _safeEmit(state.copyWith(items: [
      for (final v in state.items)
        if (v.id != id) v,
    ]));
  }
}
