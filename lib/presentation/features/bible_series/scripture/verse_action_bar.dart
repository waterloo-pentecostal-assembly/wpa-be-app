import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/bible/scripture_cubit.dart';
import '../../../design_system/components.dart';
import '../../../foundation/feedback/toast.dart';
import 'compare_sheet.dart';
import 'verse_note_sheet.dart';

/// Actions on the selected verses (note, save, compare, copy), shown at the
/// bottom of the screen while verses are selected.
class VerseActionBar extends StatelessWidget {
  const VerseActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScriptureCubit, ScriptureState>(
      buildWhen: (a, b) =>
          a.selectedVerseIds != b.selectedVerseIds ||
          a.savedVerses != b.savedVerses ||
          a.versions != b.versions,
      builder: (context, state) {
        final selection = state.selection;
        return AnimatedSize(
          duration: const Duration(milliseconds: 150),
          child: selection.isEmpty
              ? const SizedBox(width: double.infinity)
              : _Bar(state: state),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.state});

  final ScriptureState state;

  /// Unsave also removes the notes of the saved verses; confirm first.
  Future<void> _toggleSave(BuildContext context) async {
    final cubit = context.read<ScriptureCubit>();
    if (state.isSelectionSaved) {
      final withNotes = [
        for (final v in state.selectionSavedVerses)
          if (v.hasNote) v.reference,
      ];
      if (withNotes.isNotEmpty) {
        final confirmed = await showConfirmDialog(
          context,
          title: 'Remove saved verses',
          message: 'Your note on ${withNotes.join(', ')} will be deleted too.',
        );
        if (!confirmed) return;
      }
    }
    await cubit.toggleSaveSelection();
  }

  void _copy(BuildContext context) {
    final cubit = context.read<ScriptureCubit>();
    final version = state.abbreviationOf(state.bibleId);
    final reference = version.isEmpty
        ? state.selectionReference
        : '${state.selectionReference} ($version)';
    Clipboard.setData(
        ClipboardData(text: '$reference\n${state.selectionText}'));
    AppToast.info(context, 'Copied $reference');
    cubit.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScriptureCubit>();
    final isSaved = state.isSelectionSaved;
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.selectionReference,
                      style: context.text.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Clear selection',
                    onPressed: cubit.clearSelection,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Row(
                children: [
                  _Action(
                    icon: Icons.edit_note,
                    label: 'Note',
                    onTap: () => showNoteEditor(context),
                  ),
                  _Action(
                    icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                    label: isSaved ? 'Unsave' : 'Save',
                    onTap: () => _toggleSave(context),
                  ),
                  _Action(
                    icon: Icons.compare_arrows,
                    label: 'Compare',
                    onTap: () => showCompareSheet(context),
                  ),
                  _Action(
                    icon: Icons.copy,
                    label: 'Copy',
                    onTap: () => _copy(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.wpaBlue),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: context.text.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
