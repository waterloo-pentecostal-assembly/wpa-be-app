import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/infrastructure/messaging/firebase_messaging_handler.dart';

import '../application/authentication/authentication_bloc.dart';
import '../application/navigation_bar/navigation_bar_bloc.dart';
import '../injection.dart';
import 'common/loader.dart';
import 'phone/authentication/password_reset_page.dart';
import 'phone/authentication/sign_in_page.dart';
import 'phone/authentication/sign_up_page.dart';
import 'phone/index.dart';
import 'phone/splash/splash_page.dart';

class App extends StatelessWidget {
  void initializeBackgroundServices() {
    getIt<FireBaseMessagingHandler>();
  }

  @override
  Widget build(BuildContext context) {
    initializeBackgroundServices();
    //TODO: try to inject the device type here to determine whether to load the mobile view or the tablet view
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => getIt<AuthenticationBloc>()
                  ..add(
                    RequestAuthenticationState(),
                  ),
              ),
              BlocProvider(
                create: (context) => getIt<NavigationBarBloc>()
                  ..add(
                    NavigationBarEvent(
                      tab: NavigationTabEnum.HOME,
                    ),
                  ),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(fontFamily: 'Montserrat'),
              debugShowCheckedModeBanner: false,
              title: 'WPA Bible Engagement',
              onGenerateRoute: routes,
            ),
          );
        } else {
          return Loader();
        }
      },
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
  } else if (settings.name == '/index') {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return IndexPage();
      },
    );
  } else if (settings.name == '/sign_in') {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return SignInPage();
      },
    );
  } else if (settings.name == '/sign_up') {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return SignUpPage();
      },
    );
  } else if (settings.name == '/password_reset') {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return PasswordResetPage();
      },
    );
  }
  // default
  return MaterialPageRoute(
    builder: (BuildContext context) {
      return SplashPage();
    },
  );
}
