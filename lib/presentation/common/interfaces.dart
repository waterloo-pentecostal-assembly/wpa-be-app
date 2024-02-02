import 'package:flutter/material.dart';

abstract class IIndexedPage extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey;

  const IIndexedPage({Key? key, this.navigatorKey}) : super(key: key);
}
