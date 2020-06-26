import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/authentication/sign_in/sign_in_bloc.dart';

class SignInForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInBloc, SignInState>(
      listener: (BuildContext context, state) {
        // do stuff herer based on bloc's state. like navigation
        print('-----------------------');
      },
      builder: (context, state) {
        return Form(
          autovalidate: true,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  labelText: 'Email',
                ),
                autocorrect: false,
                validator: (_) {
                  print('!!!checking $state ${state.isSignInFormValid}');
                  return state.emailAddressError != ''
                      ? state.emailAddressError
                      : null;
                },
                onChanged: (value) {
                  context.bloc<SignInBloc>().add(EmailChanged(email: value));
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock),
                  labelText: 'Password',
                  // errorText: 'error :(!',
                ),
                autocorrect: false,
                obscureText: true,
                validator: (_) {
                  print('!!!checking $state ${state.isSignInFormValid}');
                  return state.passwordError != ''
                      ? state.passwordError
                      : null;
                },
                onChanged: (value) {
                  context.bloc<SignInBloc>().add(PasswordChanged(password: value));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
