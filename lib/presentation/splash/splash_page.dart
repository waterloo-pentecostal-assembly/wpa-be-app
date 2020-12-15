import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/authentication/authentication_bloc.dart';
import '../common/loader.dart';

class SplashPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Navigator.pushNamed(context, '/home');
          // NOTE: pushNamedAndRemoveUntil - Push the route with
          // the given name onto the navigator that most tightly 
          // encloses the given context, and then remove all the 
          // previous routes until the predicate returns true.

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/index',
            (Route<dynamic> route) => false,
          );
        } else if (state is Unauthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/sign_in',
            (Route<dynamic> route) => false,
          );
        }
      },
      child: _PageWidget(),
    );
  }
}

class _PageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Loader(),
    );
  }
}
