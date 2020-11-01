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

class PrayerRequestCardInherited extends InheritedWidget {
  final PrayerRequest prayerRequest;

  const PrayerRequestCardInherited({
    Key key,
    @required this.prayerRequest,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(PrayerRequestCardInherited oldWidget) {
    return oldWidget.prayerRequest != prayerRequest;
  }

  static PrayerRequestCardInherited of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PrayerRequestCardInherited>();
  }
}

class PrayerRequestCard extends StatelessWidget {
  final PrayerRequest prayerRequest;

  const PrayerRequestCard({Key key, this.prayerRequest}) : super(key: key);

  Widget build(BuildContext context) {
    return PrayerRequestCardInherited(
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
                PrayerRequestMenuButton(),
              ],
            ),
            SizedBox(height: 16),
            getIt<TextFactory>().lite(prayerRequest.request),
            SizedBox(height: 8),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [PrayButton()],
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class PrayerRequestMenuButton extends StatelessWidget {
  PrayerRequest prayerRequest(context) => PrayerRequestCardInherited.of(context).prayerRequest;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      onSelected: (value) {
        print(value.toString());
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10.0),
        ),
      ),
      color: kCardOverlayGrey,
      itemBuilder: (BuildContext context) => getPrayerRequestCardMenuItems(prayerRequest(context)),
      child: Icon(Icons.more_horiz),
    );
  }
}

class PrayerRequestUserAndDate extends StatelessWidget {
  PrayerRequest prayerRequest(context) => PrayerRequestCardInherited.of(context).prayerRequest;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Container(
            height: 30,
            width: 30,
            // child: prayerRequest(context).userSnippet.profilePhotoUrl != null
            child: (prayerRequest(context).userSnippet.profilePhotoUrl == null || prayerRequest(context).isAnonymous)
                ? Image.asset(kProfilePhotoPlaceholder)
                : FadeInImage.assetNetwork(
                    fit: BoxFit.cover,
                    placeholder: kProfilePhotoPlaceholder,
                    image: prayerRequest(context).userSnippet.profilePhotoUrl,
                  ),
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

class PrayButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<AllPrayerRequestsBloc>(
      create: (BuildContext context) => getIt<PrayerRequestsBloc>(),
      child: _PrayButton(),
    );
  }
}

class _PrayButton extends StatelessWidget {
  PrayerRequest prayerRequest(context) => PrayerRequestCardInherited.of(context).prayerRequest;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllPrayerRequestsBloc, PrayerRequestsState>(
      builder: (BuildContext context, PrayerRequestsState state) {
        if (prayerRequest(context).hasPrayed || state is PrayForRequestComplete || state is PrayForRequestError) {
          // TODO: We should should show a pop up if there is an error.
          // For now we are showing the PRAY button again. Not a huge deal since the likelyhood
          // of this error happening is very low
          return _createPrayedButton();
        } else if (state is PrayForRequestLoading) {
          return _createLoadingButton();
        }
        return _createPrayButton(context);
      },
    );
  }

  Widget _createPrayButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      child: FlatButton(
        height: 24,
        minWidth: 0,
        color: kCardGrey,
        padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () {
          BlocProvider.of<AllPrayerRequestsBloc>(context).add(PrayForRequest(
            id: prayerRequest(context).id,
          ));
        },
        child: getIt<TextFactory>().regular('PRAY'),
      ),
    );
  }

  Widget _createPrayedButton() {
    return FlatButton(
      height: 24,
      minWidth: 0,
      padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: null,
      child: getIt<TextFactory>().regular('PRAYED!'),
    );
  }

  Widget _createLoadingButton() {
    return FlatButton(
      height: 24,
      minWidth: 0,
      padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: null,
      child: getIt<TextFactory>().regular('...'),
    );
  }
}

List<PopupMenuItem> getPrayerRequestCardMenuItems(PrayerRequest prayerRequest) {
  List<PopupMenuItem> popupMenuItems = [];

  if (prayerRequest.isMine) {
    popupMenuItems.add(PopupMenuItem(
      value: {
        "id": prayerRequest.id,
        "action": PrayerActionOptions.DELETE,
      },
      child: Row(
        children: [
          Icon(Icons.delete),
          SizedBox(width: 4),
          getIt<TextFactory>().lite('DELETE'),
        ],
      ),
    ));
  } else {
    popupMenuItems.add(PopupMenuItem(
      value: {
        "id": prayerRequest.id,
        "action": PrayerActionOptions.REPORT,
      },
      child: Row(
        children: [
          Icon(Icons.error),
          SizedBox(width: 4),
          getIt<TextFactory>().lite('REPORT'),
        ],
      ),
    ));
  }

  return popupMenuItems;
}
