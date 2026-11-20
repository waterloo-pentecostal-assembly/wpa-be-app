import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/common/load_status.dart';
import '../../../../application/completions/content_detail_cubit.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../design_system/components.dart';

/// The scripture passages of a [ScriptureBody], loaded from the Bible API
/// by the [ContentDetailCubit] above it.
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
          for (final id in body.passageIds) _Passage(passageId: id),
          _Copyright(passageIds: body.passageIds),
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
        context.select((ContentDetailCubit c) => c.state.passages[passageId]);
    final passage = load?.passage;
    if (passage != null) return _PassageText(passage);
    if (load?.status == LoadStatus.failure) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Expanded(child: Text('Unable to load scripture')),
            TextButton(
              onPressed: () =>
                  context.read<ContentDetailCubit>().retryPassage(passageId),
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

class _PassageText extends StatelessWidget {
  const _PassageText(this.passage);

  final BiblePassage passage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(passage.reference, style: context.text.titleLarge),
        ),
        for (final paragraph in passage.paragraphs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SelectableText.rich(
              TextSpan(
                style: context.text.bodyLarge,
                children: verseSpans(
                  paragraph,
                  verseNumberStyle: context.textStyles.verseNumber,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// The copyright of the loaded passages, each distinct notice once.
class _Copyright extends StatelessWidget {
  const _Copyright({required this.passageIds});

  final List<String> passageIds;

  @override
  Widget build(BuildContext context) {
    final passages = context.select((ContentDetailCubit c) => c.state.passages);
    final notices = {
      for (final id in passageIds)
        if (passages[id]?.passage?.copyright case final c? when c.isNotEmpty) c,
    };
    if (notices.isEmpty) return const SizedBox.shrink();
    return Text(notices.join('\n'), style: context.text.bodySmall);
  }
}

final _verseNumber = RegExp(r'\[(\d+)\]\s*');

/// Splits [paragraph] into text spans, showing inline verse markers such as
/// `[16]` as `16 ` in [verseNumberStyle].
List<TextSpan> verseSpans(String paragraph, {TextStyle? verseNumberStyle}) {
  final spans = <TextSpan>[];
  var start = 0;
  for (final match in _verseNumber.allMatches(paragraph)) {
    if (match.start > start) {
      spans.add(TextSpan(text: paragraph.substring(start, match.start)));
    }
    spans.add(TextSpan(text: '${match[1]} ', style: verseNumberStyle));
    start = match.end;
  }
  if (start < paragraph.length) {
    spans.add(TextSpan(text: paragraph.substring(start)));
  }
  return spans;
}
