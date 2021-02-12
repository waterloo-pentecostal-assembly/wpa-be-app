import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/injection.dart';
import '../../application/admin/admin_bloc.dart';
import '../common/interfaces.dart';
import '../common/text_factory.dart';
import 'prayer_approval_page.dart';
import 'user_verification_page.dart';

class AdminPage extends IIndexedPage {
  final GlobalKey<NavigatorState> navigatorKey;

  const AdminPage({Key key, this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminBloc>(
      create: (BuildContext context) => getIt<AdminBloc>(),
      child: SafeArea(
        child: Scaffold(
          body: Navigator(
            key: navigatorKey,
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute(
                  settings: settings,
                  builder: (BuildContext context) {
                    switch (settings.name) {
                      case '/':
                        return OptionsList();
                      case '/prayer_request_approval':
                        return PrayerApprovalPage();
                      case '/user_verification':
                        return UserVerificationPage();
                    }
                    return OptionsList();
                  });
            },
          ),
        ),
      ),
    );
  }
}

class OptionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: ListView(
        children: [
          HeaderWidget(),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  BlocProvider.of<AdminBloc>(context)
                    ..add(LoadUnverifiedUsers());
                  Navigator.pushNamed(context, '/user_verification');
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  width: 150,
                  height: 125,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey[500],
                          offset: Offset(4.0, 4.0),
                          blurRadius: 15.0,
                          spreadRadius: 1.0,
                        ),
                      ]),
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        child: Icon(
                          Icons.supervised_user_circle,
                          color: Colors.amber[300],
                          size: 50,
                        ),
                      ),
                      SizedBox(height: 20),
                      getIt<TextFactory>().subHeading3('User Verification'),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  BlocProvider.of<AdminBloc>(context)
                    ..add(LoadUnverifiedPrayerRequests());
                  Navigator.pushNamed(context, '/prayer_request_approval');
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  width: 150,
                  height: 125,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey[500],
                          offset: Offset(4.0, 4.0),
                          blurRadius: 15.0,
                          spreadRadius: 1.0,
                        ),
                      ]),
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        child: Icon(
                          Icons.verified_user,
                          color: Colors.greenAccent[400],
                          size: 50,
                        ),
                      ),
                      SizedBox(height: 16),
                      getIt<TextFactory>()
                          .subHeading3('Prayer Request Approval'),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class HeaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      //decoration: BoxDecoration(color: Colors.grey.shade300),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: getIt<TextFactory>().heading('Admin Panel'),
      ),
    );
  }
}