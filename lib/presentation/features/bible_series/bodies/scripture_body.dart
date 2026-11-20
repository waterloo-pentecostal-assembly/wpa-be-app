import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/bible/scripture_cubit.dart';
import '../../../../application/common/load_status.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../design_system/components.dart';
import '../scripture/bible_version_picker.dart';
import '../scripture/passage_view.dart';

/// The scripture passages of a [ScriptureBody], loaded from the Bible API
/// by the [ScriptureCubit] above it, with a button to change the version.
class ScriptureBodyView extends StatelessWidget {
  const ScriptureBodyView({super.key, required this.body});

  final ScriptureBody body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: BibleVersionButton(),
          ),
          for (final id in body.passageIds) _Passage(passageId: id),
          _Copyright(passageIds: body.passageIds),
        ],
      ),
    );
  }
}

/// The current version's abbreviation (e.g. `KJV ▾`); opens the version
/// picker.
class BibleVersionButton extends StatelessWidget {
  const BibleVersionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final label = context.select((ScriptureCubit c) {
      final s = c.state;
      return s.bibleId == null ? null : s.abbreviationOf(s.bibleId);
    });
    if (label == null) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: () => showBibleVersionPicker(
        context,
        selectedId: context.read<ScriptureCubit>().state.preferredBibleId,
        showSeriesVersion: true,
        onSelected: context.read<ScriptureCubit>().selectBible,
      ),
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

class _Passage extends StatelessWidget {
  const _Passage({required this.passageId});

  final String passageId;

  @override
  Widget build(BuildContext context) {
    final load =
        context.select((ScriptureCubit c) => c.state.passages[passageId]);
    final passage = load?.passage;
    if (passage != null) return PassageView(passage: passage);
    if (load?.status == LoadStatus.failure) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Expanded(child: Text('Unable to load scripture')),
            TextButton(
              onPressed: () =>
                  context.read<ScriptureCubit>().retryPassage(passageId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: LoadingState(),
    );
  }
}

/// The copyright of the loaded passages, each distinct notice once.
class _Copyright extends StatelessWidget {
  const _Copyright({required this.passageIds});

  final List<String> passageIds;

  @override
  Widget build(BuildContext context) {
    final passages = context.select((ScriptureCubit c) => c.state.passages);
    final notices = {
      for (final id in passageIds)
        if (passages[id]?.passage?.copyright case final c? when c.isNotEmpty) c,
    };
    if (notices.isEmpty) return const SizedBox.shrink();
    return Text(notices.join('\n'), style: context.text.bodySmall);
  }
}
