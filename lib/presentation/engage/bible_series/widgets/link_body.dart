import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:wpa_app/presentation/common/toast_message.dart';

class LinkBodyWidget extends StatelessWidget {
  final LinkBody linkBody;
  const LinkBodyWidget({Key? key, required this.linkBody}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: generateList(context)));
  }

  List<Widget> generateList(BuildContext context) {
    List<Widget> widgetList = [];
    if (linkBody.properties.title.isNotEmpty) {
      widgetList.add(Container(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: getIt<TextFactory>()
            .subHeading(linkBody.properties.title, fontSize: 22),
      ));
    }
    widgetList.add(GestureDetector(
      onTap: () async {
        if (await canLaunch(linkBody.properties.link)) {
          await launch(linkBody.properties.link,
              forceWebView: true, enableJavaScript: true);
        } else {
          ToastMessage.showErrorToast("Error opening page", context);
        }
      },
      child: Container(
        width: getIt<LayoutFactory>()
            .getDimension(baseDimension: kLinkButtonWidth),
        margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: getIt<TextFactory>().regular(
                linkBody.properties.text,
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    ));
    return widgetList;
  }
}
