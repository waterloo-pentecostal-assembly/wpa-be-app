import 'package:material_ui/material_ui.dart';

import '../../../../domain/bible_series/entities.dart';
import '../../../design_system/theme.dart';

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
          for (final scripture in body.scriptures) _Passage(scripture),
          Text(
            '${body.bibleVersion}\n${body.attribution}',
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Passage extends StatelessWidget {
  const _Passage(this.scripture);

  final Scripture scripture;

  @override
  Widget build(BuildContext context) {
    final title = scripture.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(scripture.reference, style: context.text.titleLarge),
        ),
        if (title != null && title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(title, style: context.text.titleSmall),
          ),
        for (final number in scripture.sortedVerseNumbers)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SelectableText.rich(
              TextSpan(
                style: context.text.bodyLarge,
                children: [
                  TextSpan(
                    text: '$number ',
                    style: context.textStyles.verseNumber,
                  ),
                  TextSpan(text: scripture.verses['$number']),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
