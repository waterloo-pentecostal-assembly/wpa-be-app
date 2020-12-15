import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/injection.dart';
import '../../application/authentication/sign_in/sign_in_bloc.dart';
import 'widgets/sign_in_form.dart';

class SignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => getIt<SignInBloc>(), //SignInBloc(FirebaseAuthenticationFacade),
        child: SignInForm(),
      ),
    );
  }
}
