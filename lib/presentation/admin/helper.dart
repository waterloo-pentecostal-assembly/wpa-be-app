import 'package:material_ui/material_ui.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';

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
            child: Icon(
              Icons.arrow_back,
              size: getIt<LayoutFactory>().getDimension(baseDimension: 24.0),
            ),
          ),
          const SizedBox(width: 8),
          getIt<TextFactory>().subPageHeading(title),
        ],
      ),
    );
  }
}
