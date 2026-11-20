import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/bible/entities.dart';
import '../../domain/bible/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/common/paging.dart';
import '../common/app_events.dart';
import '../common/load_status.dart';
import 'verse_texts.dart';

/// Which saved verses the profile's list shows.
enum BibleNotesFilter { all, withNotes }

/// The verses of a saved verse, read from the Bible API in its version.
class SavedVerseTextLoad extends Equatable {
  const SavedVerseTextLoad.loading()
      : status = LoadStatus.loading,
        verses = const [];

  const SavedVerseTextLoad.loaded(this.verses) : status = LoadStatus.success;

  const SavedVerseTextLoad.failed()
      : status = LoadStatus.failure,
        verses = const [];

  final LoadStatus status;

  /// Set when [status] is success.
  final List<VerseText> verses;

  /// `16 For God so loved… 17 For God sent…`
  String get text => joinVerses(verses);

  @override
  List<Object?> get props => [status, verses];
}

class BibleNotesState extends Equatable {
  const BibleNotesState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.isEndOfList = false,
    this.isLoadingMore = false,
    this.filter = BibleNotesFilter.all,
    this.texts = const {},
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
        errorMessage,
        message,
        messageIsError,
        messageId,
      ];
}

/// The profile's list of the user's saved verses (each with an optional
/// note): paged newest first, filterable, with note editing and removing.
/// The verses' text is read from the Bible API when one is opened
/// ([loadText]). Stays in sync with the scripture reader through
/// [SavedVerseChanged] / [SavedVerseDeleted].
class BibleNotesCubit extends Cubit<BibleNotesState> {
  BibleNotesCubit({
    required IBibleReaderRepository bibleReaderRepository,
    required IBiblePassageRepository biblePassageRepository,
    required AppEventBus events,
    this.pageSize = 30,
  })  : _reader = bibleReaderRepository,
        _passages = biblePassageRepository,
        _events = events,
        super(const BibleNotesState()) {
    _subscriptions = [
      events.on<SavedVerseChanged>().listen((e) => _upsert(e.savedVerse)),
      events.on<SavedVerseDeleted>().listen((e) => _remove(e.id)),
    ];
  }

  final IBibleReaderRepository _reader;
  final IBiblePassageRepository _passages;
  final AppEventBus _events;
  final int pageSize;
  late final List<StreamSubscription<AppEvent>> _subscriptions;
  PageCursor? _cursor;

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

  /// Loads the verses of [savedVerseId] in the version they were saved in
  /// (no-op while loading or once loaded; retries after a failure).
  Future<void> loadText(String savedVerseId) async {
    final v = _find(savedVerseId);
    final current = state.texts[savedVerseId]?.status;
    if (v == null ||
        current == LoadStatus.loading ||
        current == LoadStatus.success) {
      return;
    }
    _setText(savedVerseId, const SavedVerseTextLoad.loading());
    SavedVerseTextLoad result;
    try {
      if (v.bibleId.isEmpty) throw StateError('${v.id} has no bible_id');
      result = SavedVerseTextLoad.loaded(await fetchVerseTexts(
        _passages,
        bibleId: v.bibleId,
        verseIds: v.verseIds,
      ));
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      result = const SavedVerseTextLoad.failed();
    }
    _setText(savedVerseId, result);
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
