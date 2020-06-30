import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/authentication/authentication_bloc.dart';
import 'phone/common/splash/splash_page.dart';
import 'phone/home/home_page.dart';
import 'phone/sign_in/sign_in_page.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //TODO try to inject the device type here to determine whether to load the mobile view or the tablet view
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthenticationBloc()..add(AuthenticationStateRequested()),
          //TODO: try adding auth check immediately using ..add(blah)
        ),
      ],
      child: MaterialApp(
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
  }
  return MaterialPageRoute(
    builder: (BuildContext context) {
      return SignInPage();
    },
  );
}
