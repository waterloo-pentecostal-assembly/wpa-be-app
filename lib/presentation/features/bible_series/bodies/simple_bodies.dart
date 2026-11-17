import 'package:material_ui/material_ui.dart';

import '../../../../domain/bible_series/entities.dart';
import '../../../design_system/theme.dart';

class TextBodyView extends StatelessWidget {
  const TextBodyView({super.key, required this.body});

  final TextBody body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final paragraph in body.paragraphs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SelectableText(paragraph, style: context.text.bodyLarge),
            ),
        ],
      ),
    );
  }
}

class TitleBodyView extends StatelessWidget {
  const TitleBodyView({super.key, required this.body});

  final TitleBody body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        body.text,
        style: context.text.headlineSmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}
