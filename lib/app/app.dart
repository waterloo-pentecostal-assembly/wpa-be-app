import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/audio_player/audio_player_bloc.dart';
import 'package:wpa_app/application/bible_series/bible_series_bloc.dart';

import '../application/authentication/authentication_bloc.dart';
import '../application/navigation_bar/navigation_bar_bloc.dart';
import '../presentation/authentication/password_reset_page.dart';
import '../presentation/authentication/sign_in_page.dart';
import '../presentation/authentication/sign_up_page.dart';
import '../presentation/common/layout_factory.dart';
import '../presentation/index.dart';
import '../presentation/splash/splash_page.dart';
import '../services/firebase_messaging_service.dart';
import 'injection.dart';

class App extends StatelessWidget {
  Future<void> initializeServices() async {
    await Firebase.initializeApp();
    await getIt<FirebaseMessagingService>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializeServices(),
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
                      tab: NavigationTabEnum.ENGAGE,
                    ),
                  ),
              ),
              BlocProvider(
                create: (context) => getIt<BibleSeriesBloc>()
                  ..add(
                    HasActiveBibleSeriesRequested(),
                  ),
              ),
              BlocProvider(
                create: (context) => getIt<AudioPlayerBloc>()
                  ..add(
                    InitializePlayer(),
                  ),
              )
            ],
            child: MaterialApp(
              theme: ThemeData(
                fontFamily: 'Montserrat',
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              debugShowCheckedModeBanner: false,
              title: 'WPA Bible Engagement',
              onGenerateRoute: routes,
            ),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}

void registerLayoutBuilder(context) {
  if (!getIt.isRegistered<LayoutFactory>()) {
    DeviceType deviceType = getDeviceType(context);
    getIt.registerLazySingleton<LayoutFactory>(() => LayoutFactory(deviceType));
  }
}

DeviceType getDeviceType(context) {
  double smallestDimension = MediaQuery.of(context).size.shortestSide;
  // 600 here is a common breakpoint for a typical 7-inch tablet
  bool mobile = smallestDimension < 600;
  if (mobile) {
    return DeviceType.MOBILE;
  }
  return DeviceType.TABLET;
}

Route routes(RouteSettings settings) {
  Widget widget = SplashPage();
  if (settings.name == '/') {
    widget = SplashPage();
  } else if (settings.name == '/index') {
    widget = IndexPage();
  } else if (settings.name == '/sign_in') {
    widget = SignInPage();
  } else if (settings.name == '/sign_up') {
    widget = SignUpPage();
  } else if (settings.name == '/password_reset') {
    widget = PasswordResetPage();
  }
  return MaterialPageRoute(
    builder: (BuildContext context) {
      registerLayoutBuilder(context);
      return widget;
    },
  );
}
