import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/authentication/authentication_bloc.dart';
import '../common/interfaces.dart';

class ProfilePage extends IIndexedPage {
  final GlobalKey<NavigatorState> navigatorKey;

  const ProfilePage({Key key, @required this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (BuildContext context, AuthenticationState state) {
        if (state is Unauthenticated) {
          Navigator.of(context, rootNavigator: true)
                    .pushNamed('/sign_in');
        }
      },
      child: Scaffold(
        body: Navigator(
          key: navigatorKey,
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute(
              settings: settings,
              builder: (BuildContext context) {
                switch (settings.name) {
                  case '/':
                    return ProfilePageRoot();
                  case '/privacy_policy':
                    return PrivacyPolicyPage();
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class ProfilePageRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: Column(
          children: <Widget>[
            RaisedButton(
              child: Text('Privacy Policy'),
              onPressed: () {
                Navigator.pushNamed(context, '/privacy_policy');
              },
            ),
            RaisedButton(
              child: Text('Sign Out'),
              onPressed: () {
                context.bloc<AuthenticationBloc>().add(SignOut());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: Column(
          children: <Widget>[
            Text('Privacy Policy'),
            RaisedButton(
              child: Text('Back'),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
}

/*
MultiBlocListener(
      listeners: [
        BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (BuildContext context, AuthenticationState state) {
            if (state is Unauthenticated) {
              Navigator.pushNamed(context, '/sign_in');
            }
          },
        ),
      ],
      child: 
*/
