import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/community_posts/new_post_cubit.dart';
import '../../design_system/components.dart';
import '../../foundation/feedback/overlay_form.dart';
import '../../foundation/feedback/toast.dart';
import 'post_copy.dart';

/// Shows the new prayer request / testimony form over the current screen.
void showNewPostForm(BuildContext context, PostCopy copy) {
  final factory = context.read<NewPostCubitFactory>();
  showOverlayForm(
    context,
    (_, close) => BlocProvider<NewPostCubit>(
      create: (_) => factory.create(prayerRequest: copy.isPrayerRequest),
      child: NewPostForm(copy: copy, onClose: close, toastContext: context),
    ),
  );
}

class NewPostForm extends StatelessWidget {
  const NewPostForm({
    super.key,
    required this.copy,
    required this.onClose,
    required this.toastContext,
  });

  final PostCopy copy;
  final VoidCallback onClose;

  /// Context used to show the result toast after the form closed.
  final BuildContext toastContext;

  Future<void> _post(BuildContext context) async {
    final cubit = context.read<NewPostCubit>();
    onClose();
    final error = await cubit.submit();
    if (!toastContext.mounted) return;
    error == null
        ? AppToast.info(toastContext, copy.submittedMessage)
        : AppToast.error(toastContext, error);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewPostCubit, NewPostState>(
      builder: (context, state) {
        final cubit = context.read<NewPostCubit>();
        return OverlayFormCard(
          onDismiss: onClose,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: TextField(
                keyboardType: TextInputType.multiline,
                maxLines: null,
                autofocus: true,
                onChanged: cubit.bodyChanged,
                style: context.textStyles.input,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: copy.newPostHint,
                  hintStyle: context.textStyles.input
                      .copyWith(color: Colors.grey.shade300),
                ),
              ),
            ),
            Padding(
              padding: state.bodyError.isEmpty
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(bottom: 16),
              child: Text(
                state.bodyError,
                style: context.textStyles.input.copyWith(
                  fontSize: 12,
                  color: AppColors.error.withValues(alpha: 0.8),
                ),
              ),
            ),
            Wrap(
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RoundCheckbox(
                      value: state.isAnonymous,
                      onChanged: cubit.anonymousChanged,
                    ),
                    const SizedBox(width: 4),
                    Text('Anonymous', style: context.text.bodyMedium),
                  ],
                ),
                Wrap(
                  children: [
                    PillButton(
                      label: 'CANCEL',
                      variant: PillButtonVariant.secondary,
                      onPressed: onClose,
                    ),
                    const SizedBox(width: 16),
                    PillButton(
                      label: 'POST',
                      onPressed: state.isValid ? () => _post(context) : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Small round checkbox (anonymous toggle).
class RoundCheckbox extends StatelessWidget {
  const RoundCheckbox(
      {super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          height: 18,
          width: 18,
          decoration: BoxDecoration(
            border: value ? null : Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(48),
            color: value
                ? AppColors.wpaBlue.withValues(alpha: 0.65)
                : Colors.white,
          ),
          child: value
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : const SizedBox(),
        ),
      ),
    );
  }
}
