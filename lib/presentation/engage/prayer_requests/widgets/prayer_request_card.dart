import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/constants.dart';
import '../../../../app/injection.dart';
import '../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../../domain/prayer_requests/entities.dart';
import '../../../common/helpers.dart';
import '../../../common/text_factory.dart';
import '../../../common/toast_message.dart';

enum PrayerActionOptions {
  MY_DELETE,
  REPORT,
}

class PrayerRequestCard extends StatelessWidget {
  final PrayerRequest prayerRequest;
  final Widget prayButtonOrIndicator;
  final Animation<double> animation;

  const PrayerRequestCard({
    Key key,
    @required this.prayerRequest,
    @required this.prayButtonOrIndicator,
    @required this.animation,
  }) : super(key: key);

  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
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
                PrayerRequestUserAndDate(prayerRequest: prayerRequest),
                PrayerRequestMenuButton(prayerRequest: prayerRequest),
              ],
            ),
            SizedBox(height: 16),
            getIt<TextFactory>().lite(prayerRequest.request),
            SizedBox(height: 8),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [prayButtonOrIndicator],
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
  final PrayerRequest prayerRequest;

  const PrayerRequestMenuButton({Key key, @required this.prayerRequest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      onSelected: (value) {
        value = value as MenuButtonValue;
        handleMenuButtonSelection(value, context);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10.0),
        ),
      ),
      color: kCardOverlayGrey,
      itemBuilder: (BuildContext context) => getPrayerRequestCardMenuItems(prayerRequest),
      child: Icon(Icons.more_horiz),
    );
  }

  void handleMenuButtonSelection(MenuButtonValue menuButtonValue, BuildContext context) {
    if (menuButtonValue.action == PrayerActionOptions.MY_DELETE) {
      BlocProvider.of<PrayerRequestsBloc>(context)..add(MyPrayerRequestDeleted(id: menuButtonValue.id));
    } else if (menuButtonValue.action == PrayerActionOptions.REPORT) {
      BlocProvider.of<AllPrayerRequestsBloc>(context)..add(PrayerRequestReported(id: menuButtonValue.id));
    }
  }

  List<PopupMenuItem> getPrayerRequestCardMenuItems(PrayerRequest prayerRequest) {
    List<PopupMenuItem> popupMenuItems = [];

    if (prayerRequest.isMine) {
      popupMenuItems.add(PopupMenuItem(
        value: MenuButtonValue(id: prayerRequest.id, action: PrayerActionOptions.MY_DELETE),
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
        value: MenuButtonValue(id: prayerRequest.id, action: PrayerActionOptions.REPORT),
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
}

class PrayerRequestUserAndDate extends StatelessWidget {
  final PrayerRequest prayerRequest;

  const PrayerRequestUserAndDate({Key key, @required this.prayerRequest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Container(
            height: 30,
            width: 30,
            child: (prayerRequest.userSnippet.profilePhotoUrl == null || prayerRequest.isAnonymous)
                ? Image.asset(kProfilePhotoPlaceholder)
                : FadeInImage.assetNetwork(
                    fit: BoxFit.cover,
                    placeholder: kProfilePhotoPlaceholder,
                    image: prayerRequest.userSnippet.profilePhotoUrl,
                  ),
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            () {
              if (prayerRequest.isAnonymous) {
                return getIt<TextFactory>().regular("Anonymous");
              } else {
                return getIt<TextFactory>()
                    .regular('${prayerRequest.userSnippet.firstName} ${prayerRequest.userSnippet.lastName}');
              }
            }(),
            getIt<TextFactory>().lite(toReadableDate(prayerRequest.date), fontSize: 9.0)
          ],
        )
      ],
    );
  }
}

class PrayButton extends StatelessWidget {
  final PrayerRequest prayerRequest;

  const PrayButton({Key key, @required this.prayerRequest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AllPrayerRequestsBloc>(
      create: (BuildContext context) => getIt<PrayerRequestsBloc>(),
      child: _PrayButton(
        prayerRequest: prayerRequest,
      ),
    );
  }
}

class _PrayButton extends StatelessWidget {
  final PrayerRequest prayerRequest;

  const _PrayButton({Key key, @required this.prayerRequest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AllPrayerRequestsBloc, PrayerRequestsState>(
      listener: (BuildContext context, PrayerRequestsState state) {
        if (state is PrayForRequestError) {
          ToastMessage.showErrorToast(state.message, context);
        }
      },
      builder: (BuildContext context, PrayerRequestsState state) {
        if (prayerRequest.hasPrayed || state is PrayForRequestComplete) {
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
            id: prayerRequest.id,
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
      child: getIt<TextFactory>().regular('PRAYED!', color: Colors.black54),
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
      child: getIt<TextFactory>().regular('Prayed by $amount other${getS(amount)}', color: Colors.black54),
    );
  }

  String getS(int amount) {
    if (amount == 1) {
      return '';
    }
    return 's';
  }
}

class MenuButtonValue {
  final String id;
  final PrayerActionOptions action;

  MenuButtonValue({@required this.id, @required this.action});
}
