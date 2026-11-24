import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/bible/entities.dart';
import '../../domain/bible/interfaces.dart';
import '../../domain/bible/verse_reference.dart';
import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../common/app_events.dart';
import '../common/load_status.dart';

/// A scripture passage, loaded from the Bible API.
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

/// The selected verses read in another version.
class VerseComparison extends Equatable {
  const VerseComparison({
    required this.bibleId,
    required this.status,
    this.verses = const [],
  });

  final String bibleId;
  final LoadStatus status;

  /// One entry per selected verse, in reading order (set on success).
  final List<VerseText> verses;

  @override
  List<Object?> get props => [bibleId, status, verses];
}

const _unset = Object();

class ScriptureState extends Equatable {
  const ScriptureState({
    this.passageIds = const [],
    this.seriesBibleId,
    this.preferredBibleId,
    this.versionsStatus = LoadStatus.initial,
    this.versions = const [],
    this.passages = const {},
    this.selectedVerseIds = const {},
    this.savedVerses = const [],
    this.comparison,
    this.message,
    this.messageIsError = false,
    this.messageId = 0,
  });

  /// Passage ids of the content's scripture bodies, in order.
  final List<String> passageIds;

  /// Version of the series (`scripture_bible_id`); `null` until loaded.
  final String? seriesBibleId;

  /// Version chosen by the user; `null` reads the series' version.
  final String? preferredBibleId;

  final LoadStatus versionsStatus;

  /// Available versions, sorted by language then name.
  final List<BibleVersion> versions;

  /// Passage id -> passage in [bibleId].
  final Map<String, PassageLoad> passages;

  /// Selected verse ids (see [selection] for reading order).
  final Set<String> selectedVerseIds;

  /// The user's saved verses (with their notes) of this series day, shown in
  /// whatever version is being read.
  final List<SavedVerse> savedVerses;

  /// Set while the compare view is open.
  final VerseComparison? comparison;

  /// One-shot toast ([messageId] changes for each one).
  final String? message;
  final bool messageIsError;
  final int messageId;

  /// The version passages are read in; `null` until known.
  String? get bibleId => preferredBibleId ?? seriesBibleId;

  BibleVersion? versionOf(String? id) {
    for (final v in versions) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Abbreviation of [id] (e.g. `KJV`), or '' while versions load.
  String abbreviationOf(String? id) => versionOf(id)?.abbreviation ?? '';

  /// Loaded passages in display order.
  List<BiblePassage> get loadedPassages => [
        for (final id in passageIds)
          if (passages[id]?.passage case final p?) p,
      ];

  /// Book id -> name as written in the passage references (`JHN` → `John`).
  Map<String, String> get bookNames => {
        for (final p in loadedPassages)
          if (p.verseIds.isNotEmpty)
            if (VerseRef.tryParse(p.verseIds.first)?.book case final book?)
              if (p.bookName case final name?) book: name,
      };

  /// The selected verse ids in reading order.
  List<String> get selection {
    if (selectedVerseIds.isEmpty) return const [];
    return [
      ...{
        for (final p in loadedPassages)
          for (final id in p.verseIds)
            if (selectedVerseIds.contains(id)) id,
      },
    ];
  }

  /// e.g. `John 3:16-18`.
  String referenceOf(List<String> verseIds) {
    final names = bookNames;
    return formatReference(verseIds, bookName: (b) => names[b] ?? b);
  }

  String get selectionReference => referenceOf(selection);

  /// The text of [verseIds] in the current version, from the loaded
  /// passages.
  List<VerseText> versesOf(List<String> verseIds) {
    final passages = loadedPassages;
    return [
      for (final id in verseIds)
        VerseText(
          verseId: id,
          text: passages
              .map((p) => p.verseText(id))
              .firstWhere((t) => t.isNotEmpty, orElse: () => ''),
        ),
    ];
  }

  /// The text of each selected verse in the current version.
  List<VerseText> get selectionVerses => versesOf(selection);

  /// `16 For God so loved… 17 For God did not…`
  String get selectionText => joinVerses(selectionVerses);

  /// Saved verse ids.
  Set<String> get savedVerseIds => {
        for (final v in savedVerses) ...v.verseIds,
      };

  /// Verse ids that have a note.
  Set<String> get notedVerseIds => {
        for (final v in savedVerses)
          if (v.hasNote) ...v.verseIds,
      };

  /// Saved verses with a note covering [verseId], oldest first.
  List<SavedVerse> notesFor(String verseId) => [
        for (final v in savedVerses)
          if (v.hasNote && v.verseIds.contains(verseId)) v,
      ];

  /// Whether every selected verse is saved ("Unsave" instead of "Save").
  bool get isSelectionSaved {
    final selected = selection;
    if (selected.isEmpty) return false;
    final saved = savedVerseIds;
    return selected.every(saved.contains);
  }

  /// The saved verses that include any selected verse (what "Unsave"
  /// removes).
  List<SavedVerse> get selectionSavedVerses {
    final selected = selectedVerseIds;
    return [
      for (final v in savedVerses)
        if (v.verseIds.any(selected.contains)) v,
    ];
  }

  /// The saved verse a note on the selection goes on: the smallest one that
  /// contains every selected verse. `null` when there is none (a note then
  /// saves the selection as a new saved verse).
  SavedVerse? get noteTarget {
    final selected = selection;
    if (selected.isEmpty) return null;
    SavedVerse? target;
    for (final v in savedVerses) {
      if (selected.every(v.verseIds.contains) &&
          (target == null || v.verseIds.length < target.verseIds.length)) {
        target = v;
      }
    }
    return target;
  }

  /// A version to compare with by default: another version in the same
  /// language as the current one, else any other version.
  String? get defaultCompareBibleId {
    final current = versionOf(bibleId);
    final others = versions.where((v) => v.id != bibleId);
    for (final v in others) {
      if (current != null && v.languageId == current.languageId) return v.id;
    }
    return others.isEmpty ? null : others.first.id;
  }

  ScriptureState copyWith({
    List<String>? passageIds,
    String? seriesBibleId,
    Object? preferredBibleId = _unset,
    LoadStatus? versionsStatus,
    List<BibleVersion>? versions,
    Map<String, PassageLoad>? passages,
    Set<String>? selectedVerseIds,
    List<SavedVerse>? savedVerses,
    Object? comparison = _unset,
    String? message,
    bool? messageIsError,
    int? messageId,
  }) {
    return ScriptureState(
      passageIds: passageIds ?? this.passageIds,
      seriesBibleId: seriesBibleId ?? this.seriesBibleId,
      preferredBibleId: identical(preferredBibleId, _unset)
          ? this.preferredBibleId
          : preferredBibleId as String?,
      versionsStatus: versionsStatus ?? this.versionsStatus,
      versions: versions ?? this.versions,
      passages: passages ?? this.passages,
      selectedVerseIds: selectedVerseIds ?? this.selectedVerseIds,
      savedVerses: savedVerses ?? this.savedVerses,
      comparison: identical(comparison, _unset)
          ? this.comparison
          : comparison as VerseComparison?,
      message: message ?? this.message,
      messageIsError: messageIsError ?? this.messageIsError,
      messageId: messageId ?? this.messageId,
    );
  }

  @override
  List<Object?> get props => [
        passageIds,
        seriesBibleId,
        preferredBibleId,
        versionsStatus,
        versions,
        passages,
        selectedVerseIds,
        savedVerses,
        comparison,
        message,
        messageIsError,
        messageId,
      ];
}

/// The scripture of a series content: which version it is read in, its
/// passages, verse selection and the actions on selected verses (note, save,
/// compare). Created with the content screen; [load] is called once the
/// content's passage ids are known.
class ScriptureCubit extends Cubit<ScriptureState> {
  ScriptureCubit({
    required this.bibleSeriesId,
    required this.contentId,
    required IBibleSeriesRepository bibleSeriesRepository,
    required IBiblePassageRepository biblePassageRepository,
    required IBibleVersionRepository bibleVersionRepository,
    required IBibleReaderRepository bibleReaderRepository,
    required AppEventBus events,
  })  : _bibleSeries = bibleSeriesRepository,
        _passages = biblePassageRepository,
        _versions = bibleVersionRepository,
        _reader = bibleReaderRepository,
        _events = events,
        super(const ScriptureState()) {
    // Notes and saves changed elsewhere (e.g. the profile's notes screen).
    _subscriptions = [
      events.on<SavedVerseChanged>().listen((e) => _upsert(e.savedVerse)),
      events.on<SavedVerseDeleted>().listen((e) => _remove(e.id)),
      // A version chosen elsewhere (e.g. the profile's saved verses).
      events.on<PreferredBibleChanged>().listen((e) {
        if (e.bibleId != state.preferredBibleId) _useVersion(e.bibleId);
      }),
    ];
  }

  final String bibleSeriesId;
  final String contentId;
  final IBibleSeriesRepository _bibleSeries;
  final IBiblePassageRepository _passages;
  final IBibleVersionRepository _versions;
  final IBibleReaderRepository _reader;
  final AppEventBus _events;
  late final List<StreamSubscription<AppEvent>> _subscriptions;

  /// In-flight resolution of the version to read in; cleared on failure so
  /// the next caller retries.
  Future<String>? _bibleRequest;

  /// Set once the user picks a version on this screen or elsewhere: the
  /// stored preference no longer applies.
  bool _versionChosen = false;

  /// The series (fetched once; cleared on failure so the next caller
  /// retries): its Bible version, and its title and day for saved verses.
  Future<BibleSeries>? _seriesRequest;

  Future<BibleSeries> _series() => _seriesRequest ??= _bibleSeries
          .getBibleSeriesDetails(bibleSeriesId: bibleSeriesId)
          .catchError((Object e, StackTrace st) {
        _seriesRequest = null;
        Error.throwWithStackTrace(e, st);
      });

  /// This day's saved verses: loaded once; the in-flight request is shared.
  bool _savedVersesLoaded = false;
  Future<void>? _savedVersesRequest;

  /// Distinguishes the latest compare request from stale ones.
  int _compareRequest = 0;

  void _safeEmit(ScriptureState s) {
    if (!isClosed) emit(s);
  }

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }

  bool _isThisDay(SavedVerse v) => v.contentId == contentId;

  /// Adds or replaces [v] if it belongs to this series day.
  void _upsert(SavedVerse v) {
    final known = state.savedVerses.any((x) => x.id == v.id);
    if (!known && !_isThisDay(v)) return;
    _safeEmit(state.copyWith(
      savedVerses: [
        for (final x in state.savedVerses)
          if (x.id != v.id) x,
        v,
      ]..sort((x, y) => x.createdAt.compareTo(y.createdAt)),
    ));
  }

  void _remove(String id) {
    if (!state.savedVerses.any((v) => v.id == id)) return;
    _safeEmit(state.copyWith(savedVerses: [
      for (final v in state.savedVerses)
        if (v.id != id) v,
    ]));
  }

  void _toast(String message, {bool isError = false}) =>
      _safeEmit(state.copyWith(
        message: message,
        messageIsError: isError,
        messageId: nextEffectId(),
      ));

  void _fail(String message, Object e, StackTrace st) {
    reportError(e, st);
    _toast(message, isError: true);
  }

  // ---- loading -----------------------------------------------------------

  /// Loads [passageIds] (in the user's version, or the series' version), the
  /// version list and this day's saved verses, in parallel. Does nothing
  /// without passages or when already loaded.
  Future<void> load(List<String> passageIds) async {
    if (passageIds.isEmpty || state.passageIds.isNotEmpty) return;
    _safeEmit(state.copyWith(
      passageIds: passageIds,
      passages: {for (final id in passageIds) id: const PassageLoad.loading()},
    ));
    unawaited(_loadVersions());
    unawaited(_loadSavedVerses());
    await Future.wait(passageIds.map(_loadPassage));
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

  /// Reloads the version list after a failure.
  Future<void> retryVersions() async {
    if (state.versionsStatus != LoadStatus.failure) return;
    await _loadVersions();
  }

  Future<String> _bible() async {
    final id = state.bibleId;
    if (id != null) return id;
    return _bibleRequest ??=
        _resolveBible().catchError((Object e, StackTrace st) {
      _bibleRequest = null;
      Error.throwWithStackTrace(e, st);
    });
  }

  /// The user's version if they chose one (then the series is not needed),
  /// otherwise the series' version.
  Future<String> _resolveBible() async {
    // Both requests run in parallel; each settles to a value or an error so
    // neither error goes unhandled while the other is awaited.
    final (series, preferred) = await (
      _settle(_series().then((s) => s.scriptureBibleId)),
      _settle(_reader.getPreferredBibleId()),
    ).wait;
    if (preferred.error case final e?) {
      reportError(e, preferred.stackTrace); // read in the series' version
    }
    if (series.error case final e?) {
      if (preferred.value == null) {
        Error.throwWithStackTrace(e, series.stackTrace ?? StackTrace.current);
      }
      reportError(e, series.stackTrace);
    }
    return _useBible(series.value, preferred.value);
  }

  String _useBible(String? seriesBibleId, String? preferred) {
    _safeEmit(state.copyWith(
      seriesBibleId: seriesBibleId,
      preferredBibleId: _versionChosen ? state.preferredBibleId : preferred,
    ));
    return state.bibleId ?? seriesBibleId!;
  }

  Future<void> _loadPassage(String passageId) async {
    PassageLoad result;
    String? bibleId;
    try {
      bibleId = await _bible();
      result = PassageLoad.loaded(
        await _passages.getPassage(bibleId: bibleId, passageId: passageId),
      );
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      result = const PassageLoad.failed();
    }
    // The version may have changed while loading.
    if (bibleId != null && bibleId != state.bibleId) return;
    _safeEmit(state.copyWith(passages: {...state.passages, passageId: result}));
    // Retries the saved verses if they failed (no-op once loaded).
    if (result.passage != null) unawaited(_loadSavedVerses());
  }

  Future<void> _loadVersions() async {
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

  /// The saved verses of this series day (one query; see
  /// [IBibleReaderRepository.getSavedVersesForContent]). Best-effort: the text
  /// reads fine without them. After a failure the next call retries.
  Future<void> _loadSavedVerses() {
    if (_savedVersesLoaded) return Future.value();
    return _savedVersesRequest ??=
        _fetchSavedVerses().whenComplete(() => _savedVersesRequest = null);
  }

  Future<void> _fetchSavedVerses() async {
    try {
      final loaded = await _reader.getSavedVersesForContent(contentId);
      _savedVersesLoaded = true;
      // Saves made while loading are already in the state.
      final known = {for (final v in state.savedVerses) v.id};
      _safeEmit(state.copyWith(
        savedVerses: [
          ...state.savedVerses,
          for (final v in loaded)
            if (!known.contains(v.id)) v,
        ]..sort((x, y) => x.createdAt.compareTo(y.createdAt)),
      ));
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
    }
  }

  // ---- version -----------------------------------------------------------

  /// Reads in [bibleId] from now on (`null`: the series' version), here and
  /// in every series. Clears the selection and reloads the passages.
  Future<void> selectBible(String? bibleId) async {
    if (bibleId == state.preferredBibleId) return;
    _useVersion(bibleId);
    _events.emit(PreferredBibleChanged(bibleId));
    try {
      await _reader.setPreferredBibleId(bibleId);
    } catch (e, stackTrace) {
      _fail('Unable to save your Bible version', e, stackTrace);
    }
  }

  /// Reads in [bibleId] (`null`: the series' version): clears the selection
  /// and reloads the passages if the version changes.
  void _useVersion(String? bibleId) {
    _versionChosen = true;
    final previous = state.bibleId;
    _safeEmit(state.copyWith(
      preferredBibleId: bibleId,
      selectedVerseIds: const {},
      comparison: null,
    ));
    if (state.bibleId != previous && state.bibleId != null) {
      _safeEmit(state.copyWith(passages: {
        for (final id in state.passageIds) id: const PassageLoad.loading(),
      }));
      unawaited(Future.wait(state.passageIds.map(_loadPassage)));
    }
  }

  // ---- selection ---------------------------------------------------------

  void toggleVerse(String verseId) {
    final selected = {...state.selectedVerseIds};
    if (!selected.remove(verseId)) selected.add(verseId);
    _safeEmit(state.copyWith(selectedVerseIds: selected, comparison: null));
  }

  void clearSelection() =>
      _safeEmit(state.copyWith(selectedVerseIds: const {}, comparison: null));

  /// Saves the selection (with [note], if any) as a new saved verse, with
  /// the series title and day (left out if the series can't be loaded).
  Future<SavedVerse> _saveSelection({String? note}) async {
    final verseIds = state.selection;
    final reference = state.selectionReference;
    BibleSeries? series;
    try {
      series = await _series();
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
    }
    return _reader.addSavedVerse(NewSavedVerse(
      verseIds: verseIds,
      reference: reference,
      note: note,
      seriesId: bibleSeriesId,
      contentId: contentId,
      seriesTitle: series?.title ?? '',
      day: series?.dayOf(contentId),
    ));
  }

  void _applySaved(SavedVerse v, {bool clearSelection = false}) {
    _upsert(v);
    if (clearSelection) {
      _safeEmit(state.copyWith(selectedVerseIds: const {}, comparison: null));
    }
    _events.emit(SavedVerseChanged(v));
  }

  // ---- save --------------------------------------------------------------

  /// Saves the selected verses, or, when they are all saved already, removes
  /// the saved verses that include any of them (with their notes; see
  /// [ScriptureState.selectionSavedVerses]). Clears the selection.
  Future<void> toggleSaveSelection() async {
    if (state.selection.isEmpty) return;
    if (state.isSelectionSaved) {
      await _unsaveSelection();
      return;
    }
    try {
      final saved = await _saveSelection();
      _applySaved(saved, clearSelection: true);
      _toast('Saved ${saved.reference}');
    } catch (e, stackTrace) {
      _fail('Unable to save verses', e, stackTrace);
    }
  }

  Future<void> _unsaveSelection() async {
    final toRemove = [for (final v in state.selectionSavedVerses) v.id];
    try {
      await Future.wait(toRemove.map(_reader.deleteSavedVerse));
      for (final id in toRemove) {
        _remove(id);
        _events.emit(SavedVerseDeleted(id));
      }
      clearSelection();
      _toast('Removed from saved');
    } catch (e, stackTrace) {
      _fail('Unable to remove saved verses', e, stackTrace);
    }
  }

  // ---- notes -------------------------------------------------------------

  /// Writes [note] on the selected verses: on the saved verse that contains
  /// them all ([ScriptureState.noteTarget]), or, if there is none, by saving
  /// the selection with the note. Returns whether it was saved (the
  /// selection is then cleared).
  Future<bool> saveNote(String note) async {
    final text = note.trim();
    if (text.isEmpty || state.selection.isEmpty) return false;
    final target = state.noteTarget;
    try {
      final SavedVerse saved;
      if (target != null) {
        await _reader.setNote(savedVerseId: target.id, note: text);
        saved = target.withNote(text);
      } else {
        saved = await _saveSelection(note: text);
      }
      _applySaved(saved, clearSelection: true);
      _toast('Note saved');
      return true;
    } catch (e, stackTrace) {
      _fail('Unable to save note', e, stackTrace);
      return false;
    }
  }

  /// Sets the note of a saved verse; `null` (or blank) deletes the note and
  /// keeps the verses saved. Returns whether it was saved.
  Future<bool> setNote(String savedVerseId, String? note) async {
    final text = note?.trim();
    final value = text == null || text.isEmpty ? null : text;
    final current =
        state.savedVerses.where((v) => v.id == savedVerseId).firstOrNull;
    if (current == null) return false;
    try {
      await _reader.setNote(savedVerseId: savedVerseId, note: value);
      _applySaved(current.withNote(value));
      _toast(value == null ? 'Note deleted' : 'Note saved');
      return true;
    } catch (e, stackTrace) {
      _fail(value == null ? 'Unable to delete note' : 'Unable to save note', e,
          stackTrace);
      return false;
    }
  }

  // ---- compare -----------------------------------------------------------

  /// Loads the selected verses in [bibleId] into [ScriptureState.comparison].
  /// Each passage with selected verses is requested once, from its first to
  /// its last selected verse.
  Future<void> compare(String bibleId) async {
    final selection = state.selection;
    if (selection.isEmpty) return;
    final request = ++_compareRequest;
    _safeEmit(state.copyWith(
      comparison: VerseComparison(bibleId: bibleId, status: LoadStatus.loading),
    ));
    VerseComparison result;
    try {
      final groups = <List<String>>[];
      final grouped = <String>{};
      for (final passage in state.loadedPassages) {
        final ids = [
          for (final id in passage.verseIds)
            if (selection.contains(id) && grouped.add(id)) id,
        ];
        if (ids.isNotEmpty) groups.add(ids);
      }
      final passages = await Future.wait([
        for (final ids in groups)
          _passages.getPassage(
            bibleId: bibleId,
            passageId: passageIdFor(ids.first, ids.last),
          ),
      ]);
      result = VerseComparison(
        bibleId: bibleId,
        status: LoadStatus.success,
        verses: [
          for (var i = 0; i < groups.length; i++)
            for (final id in groups[i])
              VerseText(verseId: id, text: passages[i].verseText(id)),
        ],
      );
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      result = VerseComparison(bibleId: bibleId, status: LoadStatus.failure);
    }
    if (request != _compareRequest || state.comparison == null) return;
    _safeEmit(state.copyWith(comparison: result));
  }

  /// Closes the compare view.
  void closeComparison() {
    _compareRequest++;
    _safeEmit(state.copyWith(comparison: null));
  }
}

/// The outcome of a future: its [value], or the [error] it failed with.
class _Settled<T> {
  const _Settled(this.value, [this.error, this.stackTrace]);

  final T? value;
  final Object? error;
  final StackTrace? stackTrace;
}

Future<_Settled<T>> _settle<T>(Future<T> future) => future.then(
      (value) => _Settled<T>(value),
      onError: (Object e, StackTrace st) => _Settled<T>(null, e, st),
    );
