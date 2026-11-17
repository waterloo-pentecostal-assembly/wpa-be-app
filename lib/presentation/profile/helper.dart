import 'package:material_ui/material_ui.dart';

import '../../app/constants.dart';
import '../../app/injection.dart';
import '../common/text_factory.dart';

class HeaderWidget extends StatelessWidget {
  final String title;
  const HeaderWidget({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kHeadingPadding),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          getIt<TextFactory>().subPageHeading(title),
        ],
      ),
    );
  }
}
