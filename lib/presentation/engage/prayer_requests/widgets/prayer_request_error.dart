import 'package:material_ui/material_ui.dart';

// TODO: Add reload button
class PrayerRequestsErrorWidget extends StatelessWidget {
  final String message;

  const PrayerRequestsErrorWidget({Key? key, required this.message})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Text('Unable to load prayer requests.'),
    );
  }
}
