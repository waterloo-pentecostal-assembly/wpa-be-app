import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/authentication/sign_in/sign_in_bloc.dart';

class SignInForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInBloc, SignInState>(
      listener: (BuildContext context, state) {
        // do stuff herer based on bloc's state. like navigation
        // print('---------> LISTENER STATE $state');
        //  ----------- FORM VALID ${state.isSignInFormValid}');

        if (state.signInSuccess) {
          Navigator.pushNamed(context, '/home');
        }
      },
      // buildWhen: (previous, current) {
        // Use to rebuild builder in a specific case, return true to rebuild or false otherwise
        // if (current.emailAddressError != previous.emailAddressError) {
        //   // print('errrrrrrrrrrrrrrrrrrrror changed');
        //   return true;
        // }
        // // print('no change');
        // return false;
      // },
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
                  String emailAddressError = context.bloc<SignInBloc>().state.emailAddressError;
                  return emailAddressError != ''
                      ? emailAddressError
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
                ),
                autocorrect: false,
                obscureText: true,
                validator: (_) {
                  String passwordError = context.bloc<SignInBloc>().state.passwordError;
                  return passwordError != ''
                      ? passwordError
                      : null;
                },
                onChanged: (value) {
                  context
                      .bloc<SignInBloc>()
                      .add(PasswordChanged(password: value));
                },
              ),
              RaisedButton(
                child: Text('SIGN IN'),
                onPressed: state.submitting || !state.isSignInFormValid ? null : () => context.bloc<SignInBloc>().add(SignInWithEmailAndPassword()),
              ),
              RaisedButton(
                child: Text('SIGN IN WITH GOOGLE'),
                onPressed: state.submitting ? null : () => context.bloc<SignInBloc>().add(SignInWithGoogle()),
              ),
              if (state.submitting) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(value: null),
              ]
            ],
          ),
        );
      },
    );
  }
}
