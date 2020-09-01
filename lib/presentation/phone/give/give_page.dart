import 'package:flutter/material.dart';

import '../common/interfaces.dart';

class GivePage extends IIndexedPage {
  final GlobalKey<NavigatorState> navigatorKey;

  const GivePage({Key key, @required this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Text('GIVE PAGE'),
      ),
    );
  }
}
