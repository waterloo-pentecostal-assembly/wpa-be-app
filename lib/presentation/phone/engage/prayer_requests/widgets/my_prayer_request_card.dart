import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../../../constants.dart';
import '../../../../../domain/prayer_requests/entities.dart';
import '../../../../../injection.dart';
import '../../../common/factories/text_factory.dart';
import '../../../common/helpers.dart';

enum PrayerActionOptions {
  DELETE,
  REPORT,
}

class MyPrayerRequestCardInherited extends InheritedWidget {
  final PrayerRequest prayerRequest;

  const MyPrayerRequestCardInherited({
    Key key,
    @required this.prayerRequest,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(MyPrayerRequestCardInherited oldWidget) {
    return oldWidget.prayerRequest != prayerRequest;
  }

  static MyPrayerRequestCardInherited of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyPrayerRequestCardInherited>();
  }
}

class MyPrayerRequestCard extends StatelessWidget {
  final PrayerRequest prayerRequest;
  final Animation<double> animation;

  const MyPrayerRequestCard({Key key, this.prayerRequest, this.animation}) : super(key: key);

  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: MyPrayerRequestCardInherited(
        prayerRequest: prayerRequest,
        child: Container(
          margin: EdgeInsets.all(8.0),
          width: 0.9 * MediaQuery.of(context).size.width,
          padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: kCardOverlayGrey,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.25),
                blurRadius: 8.0,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PrayerRequestUserAndDate(),
                  PrayerRequestClearButton(),
                ],
              ),
              SizedBox(height: 16),
              getIt<TextFactory>().lite(prayerRequest.request),
              SizedBox(height: 8),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  // children: [PrayButton()],
                  children: [PrayedByIndicator(amount: prayerRequest.prayedBy.length)],
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class PrayerRequestClearButton extends StatelessWidget {
  PrayerRequest prayerRequest(context) => MyPrayerRequestCardInherited.of(context).prayerRequest;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        BlocProvider.of<MyPrayerRequestsBloc>(context)
          ..add(PrayerRequestDeleted(
            id: prayerRequest(context).id,
          ));
      },
      child: Icon(Icons.clear),
    );
  }
}

class PrayerRequestUserAndDate extends StatelessWidget {
  PrayerRequest prayerRequest(context) => MyPrayerRequestCardInherited.of(context).prayerRequest;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Container(
            height: 30,
            width: 30,
            child: prayerRequest(context).userSnippet.profilePhotoUrl != null
                ? FadeInImage.assetNetwork(
                    fit: BoxFit.cover,
                    placeholder: kProfilePhotoPlaceholder,
                    image: prayerRequest(context).userSnippet.profilePhotoUrl,
                  )
                : Image.asset(kProfilePhotoPlaceholder),
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            () {
              if (prayerRequest(context).isAnonymous) {
                return getIt<TextFactory>().regular("Anonymous");
              } else {
                return getIt<TextFactory>().regular(
                    '${prayerRequest(context).userSnippet.firstName} ${prayerRequest(context).userSnippet.lastName}');
              }
            }(),
            getIt<TextFactory>().lite(toReadableDate(prayerRequest(context).date), fontSize: 9.0)
          ],
        )
      ],
    );
  }
}

class PrayedByIndicator extends StatelessWidget {
  final int amount;

  const PrayedByIndicator({Key key, @required this.amount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      height: 24,
      minWidth: 0,
      padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: null,
      child: getIt<TextFactory>().regular('Prayed by $amount other${getSingularOrPlural(amount)}'),
    );
  }

  String getSingularOrPlural(int amount) {
    if (amount == 1) {
      return '';
    }
    return 's';
  }
}
