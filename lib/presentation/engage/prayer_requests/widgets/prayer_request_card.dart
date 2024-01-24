import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';

import '../../../../app/constants.dart';
import '../../../../app/injection.dart';
import '../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../../domain/prayer_requests/entities.dart';
import '../../../common/helpers.dart';
import '../../../common/text_factory.dart';

enum PrayerActionOptions {
  MY_DELETE,
  MY_CLOSE,
  REPORT,
}

class PrayerRequestCard extends StatelessWidget {
  final PrayerRequest prayerRequest;
  final Widget prayButtonOrIndicator;
  final Animation<double> animation;

  const PrayerRequestCard({
    Key? key,
    required this.prayerRequest,
    required this.prayButtonOrIndicator,
    required this.animation,
  }) : super(key: key);

  @override
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

  const PrayerRequestMenuButton({Key? key, required this.prayerRequest})
      : super(key: key);

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
      itemBuilder: (BuildContext context) =>
          getPrayerRequestCardMenuItems(prayerRequest),
      child: Icon(Icons.more_horiz,
          size: getIt<LayoutFactory>().getDimension(baseDimension: 24.0)),
    );
  }

  void handleMenuButtonSelection(
      MenuButtonValue menuButtonValue, BuildContext context) {
    if (menuButtonValue.action == PrayerActionOptions.MY_DELETE) {
      BlocProvider.of<PrayerRequestsBloc>(context)
        ..add(MyPrayerRequestDeleted(id: menuButtonValue.id));
    } else if (menuButtonValue.action == PrayerActionOptions.REPORT) {
      BlocProvider.of<AllPrayerRequestsBloc>(context)
        ..add(PrayerRequestReported(id: menuButtonValue.id));
    } else if (menuButtonValue.action == PrayerActionOptions.MY_CLOSE) {
      BlocProvider.of<PrayerRequestsBloc>(context)
        ..add(ClosePrayerRequest(id: menuButtonValue.id));
    }
  }

  List<PopupMenuItem> getPrayerRequestCardMenuItems(
      PrayerRequest prayerRequest) {
    List<PopupMenuItem> popupMenuItems = [];

    if (prayerRequest.isMine) {
      popupMenuItems.add(PopupMenuItem(
        value: MenuButtonValue(
            id: prayerRequest.id, action: PrayerActionOptions.MY_DELETE),
        child: Row(
          children: [
            Icon(
              Icons.delete,
              size: getIt<LayoutFactory>().getDimension(baseDimension: 24.0),
            ),
            SizedBox(width: 4),
            Expanded(
              child: getIt<TextFactory>().lite('DELETE'),
            )
          ],
        ),
      ));
      if (prayerRequest.isAnswered) {
        popupMenuItems.add(PopupMenuItem(
          value: MenuButtonValue(
              id: prayerRequest.id, action: PrayerActionOptions.MY_CLOSE),
          child: Row(
            children: [
              Icon(
                Icons.check,
                size: getIt<LayoutFactory>().getDimension(baseDimension: 24.0),
              ),
              SizedBox(width: 4),
              Expanded(
                child: getIt<TextFactory>().lite('PRAYER ANSWERED'),
              )
            ],
          ),
        ));
      }
    } else {
      popupMenuItems.add(PopupMenuItem(
        value: MenuButtonValue(
            id: prayerRequest.id, action: PrayerActionOptions.REPORT),
        child: Row(
          children: [
            Icon(
              Icons.error,
              size: getIt<LayoutFactory>().getDimension(baseDimension: 24.0),
            ),
            SizedBox(width: 4),
            Expanded(
                child: getIt<TextFactory>().lite('REPORT AS INAPPROPRIATE'))
          ],
        ),
      ));
    }

    return popupMenuItems;
  }
}

class PrayerRequestUserAndDate extends StatelessWidget {
  final PrayerRequest prayerRequest;

  const PrayerRequestUserAndDate({Key? key, required this.prayerRequest})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Container(
            height: 30,
            width: 30,
            child: (prayerRequest.isAnonymous)
                ? Image.asset(kProfilePhotoPlaceholder)
                : FadeInImage.assetNetwork(
                    fit: BoxFit.cover,
                    placeholder: kProfilePhotoPlaceholder,
                    image: prayerRequest.userSnippet.thumbnailUrl ?? '',
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
                return getIt<TextFactory>().regular(
                    '${prayerRequest.userSnippet.firstName} ${prayerRequest.userSnippet.lastName}');
              }
            }(),
            getIt<TextFactory>()
                .lite(toReadableDate(prayerRequest.date), fontSize: 10.0)
          ],
        )
      ],
    );
  }
}

class PrayButton extends StatelessWidget {
  final PrayerRequest prayerRequest;

  const PrayButton({Key? key, required this.prayerRequest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _PrayButton(
      prayerRequest: prayerRequest,
    );
  }
}

class _PrayButton extends StatelessWidget {
  final PrayerRequest prayerRequest;

  const _PrayButton({Key? key, required this.prayerRequest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllPrayerRequestsBloc, PrayerRequestsState>(
      builder: (BuildContext context, PrayerRequestsState state) {
        if (prayerRequest.hasPrayed) {
          return _createPrayedButton();
        } else if (state is PrayForRequestComplete) {
          if (state.id == prayerRequest.id) {
            return _createPrayedButton();
          }
        } else if (state is PrayForRequestLoading) {
          if (state.id == prayerRequest.id) {
            return _createLoadingButton();
          }
        }
        return _createPrayButton(context);
      },
    );
  }

  Widget _createPrayButton(BuildContext context) {
    return Container(
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(
            getIt<LayoutFactory>().getDimension(baseDimension: 20.0))),
        child: TextButton(
          style: TextButton.styleFrom(
              padding: EdgeInsets.only(
                  top: 6,
                  bottom: 6,
                  left:
                      getIt<LayoutFactory>().getDimension(baseDimension: 12.0),
                  right:
                      getIt<LayoutFactory>().getDimension(baseDimension: 12.0)),
              minimumSize: Size(
                  0, getIt<LayoutFactory>().getDimension(baseDimension: 32.0)),
              backgroundColor: kCardGrey,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          onPressed: () {
            BlocProvider.of<AllPrayerRequestsBloc>(context).add(PrayForRequest(
              id: prayerRequest.id,
            ));
          },
          child: getIt<TextFactory>().regular('PRAY'),
        ),
      ),
    );
  }

  Widget _createPrayedButton() {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size(0, 24),
        padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: null,
      child: getIt<TextFactory>().regular('PRAYED!', color: Colors.black54),
    );
  }

  Widget _createLoadingButton() {
    return TextButton(
      style: TextButton.styleFrom(
          minimumSize: Size(0, 24),
          padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      onPressed: null,
      child: getIt<TextFactory>().regular('...'),
    );
  }
}

class PrayedByIndicator extends StatelessWidget {
  final int amount;

  const PrayedByIndicator({Key? key, required this.amount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
          minimumSize: Size(0, 24),
          padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      onPressed: null,
      child: getIt<TextFactory>().regular(
          'Prayed by $amount other${getS(amount)}',
          color: Colors.black54),
    );
  }

  String getS(int amount) {
    if (amount == 1) {
      return '';
    }
    return 's';
  }
}

class PendingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
          minimumSize: Size(0, 24),
          padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      onPressed: null,
      child: getIt<TextFactory>()
          .regular('Pending', color: kWarningColor.withOpacity(0.8)),
    );
  }
}

class MenuButtonValue {
  final String id;
  final PrayerActionOptions action;

  MenuButtonValue({required this.id, required this.action});
}
