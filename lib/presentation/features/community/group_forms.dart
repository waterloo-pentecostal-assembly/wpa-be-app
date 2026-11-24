import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/challenge_groups/community_cubit.dart';
import '../../../domain/challenge_groups/rules.dart';
import '../../design_system/components.dart';

/// A group's editable details.
typedef GroupDetails = ({String name, String description, bool isPublic});

/// "Create a group" sheet. [onSubmit] returns an error message, or `null`
/// when the group was created (the sheet closes).
Future<void> showCreateGroupSheet(
  BuildContext context, {
  required Future<String?> Function(GroupDetails details) onSubmit,
}) =>
    _showSheet(
      context,
      GroupDetailsFormSheet(
        title: 'Create a challenge group',
        intro: 'You can invite people next, or share the group code.',
        submitLabel: 'Create',
        onSubmit: onSubmit,
      ),
    );

/// "Edit group" sheet, prefilled with [initial]. [onSubmit] returns an error
/// message, or `null` when saved (the sheet closes).
Future<void> showEditGroupSheet(
  BuildContext context, {
  required GroupDetails initial,
  required Future<String?> Function(GroupDetails details) onSubmit,
}) =>
    _showSheet(
      context,
      GroupDetailsFormSheet(
        title: 'Edit group',
        submitLabel: 'Save',
        initial: initial,
        onSubmit: onSubmit,
      ),
    );

/// Name, optional description and a public switch, with live validation and
/// a busy state while [onSubmit] runs.
class GroupDetailsFormSheet extends StatefulWidget {
  const GroupDetailsFormSheet({
    super.key,
    required this.title,
    this.intro,
    required this.submitLabel,
    this.initial,
    required this.onSubmit,
  });

  final String title;
  final String? intro;
  final String submitLabel;
  final GroupDetails? initial;
  final Future<String?> Function(GroupDetails details) onSubmit;

  @override
  State<GroupDetailsFormSheet> createState() => _GroupDetailsFormSheetState();
}

class _GroupDetailsFormSheetState extends State<GroupDetailsFormSheet> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _description =
      TextEditingController(text: widget.initial?.description ?? '');
  late bool _isPublic = widget.initial?.isPublic ?? false;
  bool _busy = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    void changed() => setState(() => _submitError = null);
    _name.addListener(changed);
    _description.addListener(changed);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  String get _nameError => CommunityCubit.groupNameError(_name.text);
  String get _descriptionError =>
      CommunityCubit.groupDescriptionError(_description.text);

  bool get _canSubmit =>
      !_busy && _nameError.isEmpty && _descriptionError.isEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    final error = await widget.onSubmit((
      name: _name.text,
      description: _description.text,
      isPublic: _isPublic,
    ));
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _submitError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    // A blank name is only flagged once something was typed.
    final nameError =
        _name.text.isEmpty || _nameError.isEmpty ? null : _nameError;
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
            if (widget.intro != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(widget.intro!, style: context.textStyles.muted),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('group-name'),
              controller: _name,
              autofocus: widget.initial == null,
              enabled: !_busy,
              maxLength: kMaxChallengeGroupNameLength,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Group name',
                errorText: nameError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('group-description'),
              controller: _description,
              enabled: !_busy,
              minLines: 2,
              maxLines: 4,
              maxLength: kMaxChallengeGroupDescriptionLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Who is it for? When do you read?',
                errorText: _descriptionError.isEmpty ? null : _descriptionError,
                border: const OutlineInputBorder(),
              ),
            ),
            SwitchRow(
              title: 'Public group',
              subtitle: _isPublic
                  ? 'Anyone can find and join it in "Find a group". Its '
                      "members' names and photos are visible to everyone."
                  : 'Only people you invite or who have the code can join.',
              value: _isPublic,
              enabled: !_busy,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
            if (_submitError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  _submitError!,
                  style:
                      context.text.bodySmall?.copyWith(color: AppColors.error),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.submitLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Join with a code" sheet. [onSubmit] returns an error message, or `null`
/// when the group was joined (the sheet closes).
Future<void> showJoinGroupSheet(
  BuildContext context, {
  required Future<String?> Function(String code) onSubmit,
}) =>
    _showSheet(
      context,
      GroupTextFormSheet(
        title: 'Join a challenge group',
        description: 'Enter the 6-character code a group member shared '
            'with you.',
        label: 'Group code',
        submitLabel: 'Join',
        maxLength: 7,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 -]')),
        ],
        validate: CommunityCubit.codeError,
        isComplete: CommunityCubit.isCompleteCode,
        onSubmit: onSubmit,
      ),
    );

Future<void> _showSheet(BuildContext context, Widget sheet) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => sheet,
    );

/// A one-field form in a bottom sheet: live validation, a busy state while
/// [onSubmit] runs, and its error shown under the field.
class GroupTextFormSheet extends StatefulWidget {
  const GroupTextFormSheet({
    super.key,
    required this.title,
    required this.description,
    required this.label,
    required this.submitLabel,
    required this.validate,
    required this.isComplete,
    required this.onSubmit,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters = const [],
  });

  final String title;
  final String description;
  final String label;
  final String submitLabel;

  /// Validation message for the current text (`''` when valid).
  final String Function(String value) validate;

  /// Whether the text can be submitted.
  final bool Function(String value) isComplete;
  final Future<String?> Function(String value) onSubmit;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter> inputFormatters;

  @override
  State<GroupTextFormSheet> createState() => _GroupTextFormSheetState();
}

class _GroupTextFormSheetState extends State<GroupTextFormSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _submitError = null));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy &&
      widget.isComplete(_controller.text) &&
      widget.validate(_controller.text).isEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    final error = await widget.onSubmit(_controller.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _submitError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final validation = widget.validate(_controller.text);
    final error = _submitError ?? (validation.isEmpty ? null : validation);
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
            const SizedBox(height: AppSpacing.sm),
            Text(widget.description, style: context.textStyles.muted),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_busy,
              maxLength: widget.maxLength,
              textCapitalization: widget.textCapitalization,
              inputFormatters: widget.inputFormatters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: widget.label,
                errorText: error,
                errorMaxLines: 2,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.submitLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
