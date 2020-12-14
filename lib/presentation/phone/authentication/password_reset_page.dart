import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/authentication/password_reset/password_reset_bloc.dart';
import '../../../app/injection.dart';
import 'widgets/password_reset_form.dart';

class PasswordResetPage extends StatelessWidget {
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
