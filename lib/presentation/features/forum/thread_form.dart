import 'package:material_ui/material_ui.dart';

import '../../design_system/components.dart';
import '../../foundation/feedback/overlay_form.dart';

/// Shows the thread title form ("POST" for new threads, "SAVE" for edits).
void showThreadForm(
  BuildContext context, {
  String? initialTitle,
  String saveLabel = 'POST',
  required ValueChanged<String> onSave,
}) {
  showOverlayForm(
    context,
    (_, close) => ThreadForm(
      initialTitle: initialTitle,
      saveLabel: saveLabel,
      onCancel: close,
      onSave: (title) {
        close();
        onSave(title);
      },
    ),
  );
}

class ThreadForm extends StatefulWidget {
  const ThreadForm({
    super.key,
    this.initialTitle,
    this.saveLabel = 'POST',
    required this.onCancel,
    required this.onSave,
  });

  final String? initialTitle;
  final String saveLabel;
  final VoidCallback onCancel;
  final ValueChanged<String> onSave;

  @override
  State<ThreadForm> createState() => _ThreadFormState();
}

class _ThreadFormState extends State<ThreadForm> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialTitle ?? '');

  bool get _isValid => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = context.textStyles.input;
    return OverlayFormCard(
      onDismiss: widget.onCancel,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: style,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Thread Title',
              hintStyle: style.copyWith(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          children: [
            PillButton(
              label: 'CANCEL',
              variant: PillButtonVariant.secondary,
              onPressed: widget.onCancel,
            ),
            const SizedBox(width: 16),
            PillButton(
              label: widget.saveLabel,
              onPressed:
                  _isValid ? () => widget.onSave(_controller.text) : null,
            ),
          ],
        ),
      ],
    );
  }
}
