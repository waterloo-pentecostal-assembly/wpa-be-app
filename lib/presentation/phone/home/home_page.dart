import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/presentation/common/widgets/bottom_navigation_bar.dart';

import '../../../application/authentication/authentication_bloc.dart';
import '../../../application/bible_series/bible_series_bloc.dart';
import '../../../injection.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BibleSeriesBloc>(
          create: (BuildContext context) => getIt<BibleSeriesBloc>(),
          // e.g. Use to get current study for home page
        ),
      ],
      child: TestWidget(),
    );
  }
}

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (BuildContext context, AuthenticationState state) {
            if (state is Unauthenticated) {
              Navigator.pushNamed(context, '/sign_in');
            }
          },
        ),
      ],
      child: SafeArea(
        child: Scaffold(
          // bottomNavigationBar: BottomNavigation(currentIndex: 0,),
          body: Column(
            children: <Widget>[
              Container(
                child: Text('HOME!'),
              ),
              RaisedButton(
                child: Text('Engage'),
                onPressed: () {
                  Navigator.pushNamed(context, '/engage');
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
      ),
    );
  }
}
