import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/bible/scripture_cubit.dart';
import '../../../../domain/bible/entities.dart';
import '../../../design_system/components.dart';
import 'note_editor_sheet.dart';

/// Opens the note editor for [savedVerse], or (without it) for the selected
/// verses: the note then goes on the saved verse that contains them all
/// ([ScriptureState.noteTarget]), or saves them with the note.
Future<void> showNoteEditor(BuildContext context, {SavedVerse? savedVerse}) {
  final cubit = context.read<ScriptureCubit>();
  final state = cubit.state;
  final target = savedVerse ?? state.noteTarget;
  final forSelection = savedVerse == null;
  // The verses are on screen, so they are quoted in the version being read.
  final reference = target?.reference ?? state.selectionReference;
  final version = state.abbreviationOf(state.bibleId);
  final existingNote = target?.note;
  return showNoteEditorSheet(
    context,
    title: version.isEmpty ? reference : '$reference ($version)',
    quote: target == null
        ? state.selectionText
        : joinVerses(state.versesOf(target.verseIds)),
    initialNote: existingNote ?? '',
    onSave: (note) =>
        forSelection ? cubit.saveNote(note) : cubit.setNote(target!.id, note),
    onDelete: existingNote == null
        ? null
        : () async {
            final ok = await cubit.setNote(target!.id, null);
            if (ok && forSelection) cubit.clearSelection();
            return ok;
          },
  );
}

/// Opens the note on [verseId] (or, with several, the list of its notes).
Future<void> showVerseNotes(BuildContext context, String verseId) {
  final cubit = context.read<ScriptureCubit>();
  final notes = cubit.state.notesFor(verseId);
  if (notes.isEmpty) return Future.value();
  if (notes.length == 1) {
    return showNoteEditor(context, savedVerse: notes.single);
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _VerseNotesList(verseId: verseId),
    ),
  );
}

/// The notes on a verse; tap one to edit it.
class _VerseNotesList extends StatelessWidget {
  const _VerseNotesList({required this.verseId});

  final String verseId;

  @override
  Widget build(BuildContext context) {
    final notes = context
        .select((ScriptureCubit c) => c.state.savedVerses)
        .where((v) => v.hasNote && v.verseIds.contains(verseId))
        .toList();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('Notes', style: context.text.titleLarge),
        ),
        for (final note in notes)
          ListTile(
            title: Text(note.reference, style: context.text.titleSmall),
            subtitle: Text(
              note.note ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showNoteEditor(context, savedVerse: note),
          ),
      ],
    );
  }
}
