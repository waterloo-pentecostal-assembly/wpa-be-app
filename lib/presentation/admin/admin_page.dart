import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/admin/admin_bloc.dart';

import '../../app/injection.dart';
import '../common/interfaces.dart';
import '../common/text_factory.dart';

class AdminPage extends IIndexedPage {
  final GlobalKey<NavigatorState> navigatorKey;

  const AdminPage({Key key, this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminBloc>(
      create: (BuildContext context) => getIt<AdminBloc>(),
      child: OptionsList(),
    );
  }
}

class OptionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          child: getIt<TextFactory>().regularButton('Prayer Requests Approval'),
        ),
        Container(
          child: getIt<TextFactory>().regularButton('New User Verification'),
        ),
      ],
    );
  }
}
