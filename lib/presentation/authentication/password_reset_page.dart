import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/injection.dart';
import '../../application/authentication/password_reset/password_reset_bloc.dart';
import 'widgets/password_reset_form.dart';

class PasswordResetPage extends StatelessWidget {
  const PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => getIt<PasswordResetBloc>(),
        child: PasswordResetForm(),
      ),
    );
  }
}
