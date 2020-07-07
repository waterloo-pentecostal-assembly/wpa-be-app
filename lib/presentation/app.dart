import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/authentication/authentication_bloc.dart';
import '../injection.dart';
import 'phone/audio_player/audio_player_page.dart';
import 'phone/engage/engage_page.dart';
import 'phone/home/home_page.dart';
import 'phone/sign_in/sign_in_page.dart';
import 'phone/splash/splash_page.dart';

// TODO !!! implement navigation bar the proper way. See: https://stackoverflow.com/questions/49681415/flutter-persistent-navigation-bar-with-named-routes

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //TODO try to inject the device type here to determine whether to load the mobile view or the tablet view
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AuthenticationBloc>()..add(RequestAuthenticationState()),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Montserrat'),
        debugShowCheckedModeBanner: false,
        title: 'WPA Bible Engagement',
        onGenerateRoute: routes,
      ),
    );
  }
}

Route routes(RouteSettings settings) {
  if (settings.name == '/') {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return SplashPage();
      },
    );
  } else if (settings.name == '/sign_in') {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return SignInPage();
      },
    );
  } else if (settings.name == '/home') {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return HomePage();
      },
    );
  } else if (settings.name == '/audio_player') {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return AudioPlayer();
      },
    );
  } else if (settings.name == '/engage') {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return EngagePage();
      },
    );
  }
  return MaterialPageRoute(
    builder: (BuildContext context) {
      return SignInPage();
    },
  );
}
