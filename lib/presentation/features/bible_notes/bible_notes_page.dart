import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/bible/bible_notes_cubit.dart';
import '../../../application/common/load_status.dart';
import '../../../domain/bible/entities.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/toast.dart';
import '../../foundation/formatting/dates.dart';
import '../../foundation/layout/content_constraint.dart';
import '../../foundation/navigation/app_navigator.dart';
import '../bible_series/scripture/bible_version_picker.dart';
import '../bible_series/scripture/note_editor_sheet.dart';

/// The user's saved verses (each with an optional note), newest first,
/// filterable. Tap one for its full text and actions. Expects a [BibleNotesCubit] above it.
class BibleNotesPage extends StatelessWidget {
  const BibleNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BibleNotesCubit, BibleNotesState>(
      listenWhen: (a, b) => a.messageId != b.messageId && b.message != null,
      listener: (context, s) => s.messageIsError
          ? AppToast.error(context, s.message!)
          : AppToast.info(context, s.message!),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const AppHeader(title: 'Notes & Saved Verses'),
              const ContentConstraint(child: _Filters()),
              Expanded(
                child: BlocBuilder<BibleNotesCubit, BibleNotesState>(
                  builder: (context, state) {
                    if (state.status.isFailure) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ErrorState(state.errorMessage ?? '', centered: false),
                          TextButton(
                            onPressed: context.read<BibleNotesCubit>().load,
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }
                    if (state.status.isLoading) return const LoadingState();
                    return _List(state: state);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters();

  static const _labels = {
    BibleNotesFilter.all: 'All',
    BibleNotesFilter.withNotes: 'With notes',
  };

  @override
  Widget build(BuildContext context) {
    final selected = context.select((BibleNotesCubit c) => c.state.filter);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final MapEntry(key: filter, value: label) in _labels.entries)
            ChoiceChip(
              label: Text(label),
              selected: filter == selected,
              onSelected: (_) =>
                  context.read<BibleNotesCubit>().setFilter(filter),
            ),
        ],
      ),
    );
  }
}

class _List extends StatefulWidget {
  const _List({required this.state});

  final BibleNotesState state;

  @override
  State<_List> createState() => _ListState();
}

class _ListState extends State<_List> {
  static const _scrollThreshold = 200.0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final p = _scrollController.position;
      if (p.maxScrollExtent - p.pixels <= _scrollThreshold) {
        context.read<BibleNotesCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static String _emptyMessage(BibleNotesFilter filter) => switch (filter) {
        BibleNotesFilter.all => 'No saved verses yet. '
            'Tap a verse while reading to save it or add a note.',
        BibleNotesFilter.withNotes => 'No notes yet',
      };

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final items = state.visibleItems;
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (items.isEmpty && state.isEndOfList)
          EmptyState(_emptyMessage(state.filter)),
        for (final a in items)
          ContentConstraint(child: SavedVerseTile(savedVerse: a)),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: LoadingState(),
          )
        else if (!state.isEndOfList)
          // Also reachable when a filter leaves too few rows to scroll.
          Center(
            child: TextButton(
              onPressed: context.read<BibleNotesCubit>().loadMore,
              child: const Text('Load more'),
            ),
          ),
      ],
    );
  }
}

/// Where it was saved: `Hope in Hard Times · Day 3` ('' if unknown).
String savedFrom(SavedVerse v) => [
      if (v.seriesTitle.isNotEmpty) v.seriesTitle,
      if (v.day case final day?) 'Day $day',
    ].join(' · ');

/// [savedFrom] in muted text, or nothing when unknown.
class _SavedFrom extends StatelessWidget {
  const _SavedFrom(this.savedVerse);

  final SavedVerse savedVerse;

  @override
  Widget build(BuildContext context) {
    final text = savedFrom(savedVerse);
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: context.textStyles.muted,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A saved verse: reference, where it was saved (series · day), date and its
/// note (if any). The verses' text is
/// only loaded in the details ([showSavedVerseDetails]).
class SavedVerseTile extends StatelessWidget {
  const SavedVerseTile({super.key, required this.savedVerse});

  final SavedVerse savedVerse;

  @override
  Widget build(BuildContext context) {
    final v = savedVerse;
    return InkWell(
      onTap: () => showSavedVerseDetails(context, v),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.bookmark, color: AppColors.wpaBlue),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.reference, style: context.text.titleSmall),
                  _SavedFrom(v),
                  Text(
                    DateFormats.shortDate(v.createdAt),
                    style: context.text.bodySmall,
                  ),
                  if (v.note case final note?) _NoteBox(note, maxLines: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox(this.note, {this.maxLines});

  final String note;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardOverlayGrey,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        note,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: context.text.bodyMedium,
      ),
    );
  }
}

/// A saved verse in a sheet: the verses (loaded from the Bible API in the
/// version they were saved in), its note, and Open reading, Add note / Edit
/// note and Remove. The sheet follows changes to the saved verse.
Future<void> showSavedVerseDetails(BuildContext context, SavedVerse v) {
  final cubit = context.read<BibleNotesCubit>()..loadText(v.id);
  final navigator = context.navigator;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _SavedVerseDetails(
        savedVerseId: v.id,
        onOpenReading: navigator.openContent,
      ),
    ),
  );
}

class _SavedVerseDetails extends StatelessWidget {
  const _SavedVerseDetails({
    required this.savedVerseId,
    required this.onOpenReading,
  });

  final String savedVerseId;
  final void Function({
    required String seriesId,
    required String contentId,
    String? contentType,
  }) onOpenReading;

  void _editNote(BuildContext context, SavedVerse v) {
    final cubit = context.read<BibleNotesCubit>();
    showNoteEditorSheet(
      context,
      title: v.reference,
      quote: cubit.state.texts[v.id]?.text ?? '',
      initialNote: v.note ?? '',
      onSave: (note) => cubit.setNote(v.id, note),
      onDelete: v.hasNote ? () => cubit.setNote(v.id, null) : null,
    );
  }

  Future<void> _remove(BuildContext context, SavedVerse v) async {
    final cubit = context.read<BibleNotesCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove saved verse',
      message: v.hasNote
          ? 'Remove ${v.reference} from your saved verses? Your note will be '
              'deleted too.'
          : 'Remove ${v.reference} from your saved verses?',
    );
    if (!confirmed) return;
    if (await cubit.remove(v.id) && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.select((BibleNotesCubit c) =>
        c.state.items.where((x) => x.id == savedVerseId).firstOrNull);
    if (v == null) return const SizedBox.shrink();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      children: [
        Row(
          children: [
            const Icon(Icons.bookmark, color: AppColors.wpaBlue),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(v.reference, style: context.text.titleMedium)),
            _VersionButton(savedVerseId: v.id),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _SavedFrom(v),
        Text(
          'Saved ${DateFormats.shortDate(v.createdAt)}',
          style: context.text.bodySmall,
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: _SavedVerseText(savedVerseId: v.id),
        ),
        if (v.note case final note?) _NoteBox(note),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onOpenReading(seriesId: v.seriesId, contentId: v.contentId);
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Open reading'),
            ),
            TextButton.icon(
              onPressed: () => _editNote(context, v),
              icon: Icon(v.hasNote ? Icons.edit_outlined : Icons.edit_note),
              label: Text(v.hasNote ? 'Edit note' : 'Add note'),
            ),
            TextButton.icon(
              onPressed: () => _remove(context, v),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          ],
        ),
      ],
    );
  }
}

/// The version the verses are shown in (e.g. `KJV ▾`); opens the version
/// picker. Choosing one changes the user's version everywhere.
class _VersionButton extends StatelessWidget {
  const _VersionButton({required this.savedVerseId});

  final String savedVerseId;

  void _pick(BuildContext context) {
    final cubit = context.read<BibleNotesCubit>();
    final state = cubit.state;
    showBibleVersionPicker(
      context,
      source: cubit,
      versionsOf: (s) => (status: s.versionsStatus, versions: s.versions),
      onRetry: cubit.retryVersions,
      selectedId: state.preferredBibleId,
      showSeriesVersion: true,
      // Without a preference the text is in its series' version.
      seriesBibleId: state.preferredBibleId == null
          ? state.texts[savedVerseId]?.bibleId
          : null,
      onSelected: cubit.selectBible,
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = context.select((BibleNotesCubit c) =>
        c.state.abbreviationOf(c.state.texts[savedVerseId]?.bibleId));
    return TextButton.icon(
      onPressed: () => _pick(context),
      icon: const Icon(Icons.menu_book_outlined, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.isEmpty ? 'Version' : label),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }
}

/// The verses of a saved verse: loading, failed (+ Retry) or the text.
class _SavedVerseText extends StatelessWidget {
  const _SavedVerseText({required this.savedVerseId});

  final String savedVerseId;

  @override
  Widget build(BuildContext context) {
    final load =
        context.select((BibleNotesCubit c) => c.state.texts[savedVerseId]);
    if (load == null || load.status.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: LoadingState(),
      );
    }
    if (load.status.isFailure || load.text.isEmpty) {
      return Row(
        children: [
          const Expanded(child: Text('Unable to load scripture')),
          TextButton(
            onPressed: () =>
                context.read<BibleNotesCubit>().loadText(savedVerseId),
            child: const Text('Retry'),
          ),
        ],
      );
    }
    return Text(
      load.text,
      style: context.text.bodyLarge?.copyWith(height: 1.5),
    );
  }
}
