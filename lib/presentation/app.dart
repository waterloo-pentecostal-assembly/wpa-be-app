import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/authentication/authentication_bloc.dart';
import 'package:wpa_app/presentation/common/splash/splash_page.dart';
import 'package:wpa_app/presentation/phone/sign_in/sign_in_page.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //TODO try to inject the device type here to determine whether to load the mobile view or the tablet view
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthenticationBloc(),
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
  // TODO: Use switch case here
  if (settings.name == '/') {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return SplashPage();
      },
    );
  }

  return MaterialPageRoute(
    builder: (BuildContext context) {
      return SignInPage();
    },
  );
}
