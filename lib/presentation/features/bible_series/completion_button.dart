import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/completions/content_detail_cubit.dart';
import '../../design_system/tokens.dart';

/// Large check button: grey to complete, green to undo.
class CompletionButton extends StatelessWidget {
  const CompletionButton({super.key});

  static const _size = 60.0;

  @override
  Widget build(BuildContext context) {
    final isComplete =
        context.select((ContentDetailCubit c) => c.state.isComplete);
    if (isComplete == null) return const SizedBox.shrink();
    final cubit = context.read<ContentDetailCubit>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Semantics(
          button: true,
          label: isComplete ? 'Mark as incomplete' : 'Mark as complete',
          child: InkWell(
            customBorder: const CircleBorder(),
            splashColor: isComplete ? null : Colors.lightGreenAccent,
            onTap: isComplete ? cubit.undoComplete : cubit.complete,
            child: Icon(
              Icons.check_circle,
              size: _size,
              color: isComplete
                  ? AppColors.success.withValues(alpha: 0.8)
                  : Colors.black87.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
