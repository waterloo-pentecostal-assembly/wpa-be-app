import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/authentication/authentication_bloc.dart';
import '../application/navigation_bar/navigation_bar_bloc.dart';
import '../injection.dart';
import 'phone/index.dart';
import 'phone/sign_in/sign_in_page.dart';
import 'phone/splash/splash_page.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //TODO try to inject the device type here to determine whether to load the mobile view or the tablet view
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
                tab: NavigationTabEnum.home,
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
  }
  // default
  return MaterialPageRoute(
    builder: (BuildContext context) {
      return SplashPage();
    },
  );
}
