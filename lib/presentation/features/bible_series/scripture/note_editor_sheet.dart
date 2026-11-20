import 'package:material_ui/material_ui.dart';

import '../../../design_system/components.dart';

/// Opens a [NoteEditorSheet] in a modal bottom sheet.
Future<void> showNoteEditorSheet(
  BuildContext context, {
  required String title,
  required String quote,
  required Future<bool> Function(String note) onSave,
  String initialNote = '',
  Future<bool> Function()? onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => NoteEditorSheet(
      title: title,
      quote: quote,
      initialNote: initialNote,
      onSave: onSave,
      onDelete: onDelete,
    ),
  );
}

/// Writes or edits a note on verses: [title] (e.g. `John 3:16 (KJV)`), the
/// verses' text, a note field, Cancel / Save and, when [onDelete] is set, a
/// delete button (after confirmation). The sheet closes when [onSave] or
/// [onDelete] reports success.
class NoteEditorSheet extends StatefulWidget {
  const NoteEditorSheet({
    super.key,
    required this.title,
    required this.quote,
    required this.onSave,
    this.initialNote = '',
    this.onDelete,
  });

  final String title;
  final String quote;
  final String initialNote;
  final Future<bool> Function(String note) onSave;
  final Future<bool> Function()? onDelete;

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialNote);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(Future<bool> Function() action) async {
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete note',
      message: 'Delete this note? The verses stay saved.',
    );
    if (!confirmed || !mounted) return;
    await _run(widget.onDelete!);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_busy && _controller.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: context.text.titleMedium),
            if (widget.quote.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  widget.quote,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.muted,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _controller,
              autofocus: widget.initialNote.isEmpty,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Write a note',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (widget.onDelete != null)
                  IconButton(
                    tooltip: 'Delete note',
                    onPressed: _busy ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.error,
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: canSave
                      ? () => _run(() => widget.onSave(_controller.text))
                      : null,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
