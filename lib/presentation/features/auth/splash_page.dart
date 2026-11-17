import 'package:material_ui/material_ui.dart';

import '../../design_system/components.dart';

/// Shown while the authentication state is resolved; the router redirects.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: LoadingState());
}
