import 'package:flutter/material.dart';

import '../common/interfaces.dart';

class GivePage extends IIndexedPage {
  final GlobalKey<NavigatorState> navigatorKey;

  const GivePage({Key? key, required this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          child: Text('give page'),
        ),
      ),
    );
  }
}

// class GiveWebVeiw extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     if (await canLaunch(url)) {
//       await launch(
//         url,
//         forceSafariVC: true,
//         forceWebView: true,
//         enableJavaScript: true,
//       );
//     } else {
//       throw 'Could not launch $url';
//     }
//     return Container(

//     );
//   }
// }

// https://www.canadahelps.org/en/dne/15479
// https://www.digitalocean.com/community/tutorials/flutter-url-launcher

// packages: https://pub.dev/packages/webview_flutter (https://www.youtube.com/watch?v=RA-vLF_vnng&ab_channel=Flutter)
// or https://pub.dev/packages/url_launcher
