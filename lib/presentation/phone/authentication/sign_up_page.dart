import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/authentication/sign_up/sign_up_bloc.dart';
import '../../../app/injection.dart';
import 'widgets/sign_up_form.dart';

class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => getIt<SignUpBloc>(), //SignInBloc(FirebaseAuthenticationFacade),
        child: SignUpForm(),
      ),
    );
  }
}
