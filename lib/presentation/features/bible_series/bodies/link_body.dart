import 'package:material_ui/material_ui.dart';

import '../../../../domain/bible_series/entities.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/tokens.dart';
import '../../../foundation/platform/external_links.dart';

class LinkBodyView extends StatelessWidget {
  const LinkBodyView({super.key, required this.body});

  final LinkBody body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          if (body.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(body.title, style: context.text.headlineSmall),
            ),
          Semantics(
            button: true,
            link: true,
            child: GestureDetector(
              onTap: () => openExternal(context, tryParseUri(body.link)),
              child: Container(
                constraints:
                    const BoxConstraints(minWidth: AppSizes.linkButtonWidth),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardGrey,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Text(
                  body.text,
                  style: context.text.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
