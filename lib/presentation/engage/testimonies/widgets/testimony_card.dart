import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/testimonies/testimonies_bloc.dart';
import 'package:wpa_app/domain/testimonies/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';

import '../../../../app/constants.dart';
import '../../../../app/injection.dart';
import '../../../common/helpers.dart';
import '../../../common/text_factory.dart';

enum TestimonyActionOptions {
  MY_DELETE,
  MY_CLOSE,
  REPORT,
}

class TestimonyCard extends StatelessWidget {
  final Testimony testimony;
  final Widget praiseButtonOrIndicator;
  final Animation<double> animation;

  const TestimonyCard({
    Key? key,
    required this.testimony,
    required this.praiseButtonOrIndicator,
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
                TestimoniesUserAndDate(testimony: testimony),
                TestimoniesMenuButton(testimony: testimony),
              ],
            ),
            SizedBox(height: 16),
            getIt<TextFactory>().lite(testimony.request),
            SizedBox(height: 8),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [praiseButtonOrIndicator],
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class TestimoniesMenuButton extends StatelessWidget {
  final Testimony testimony;

  const TestimoniesMenuButton({Key? key, required this.testimony})
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
          getTestimonyCardMenuItems(testimony),
      child: Icon(Icons.more_horiz,
          size: getIt<LayoutFactory>().getDimension(baseDimension: 24.0)),
    );
  }

  void handleMenuButtonSelection(
      MenuButtonValue menuButtonValue, BuildContext context) {
    if (menuButtonValue.action == TestimonyActionOptions.MY_DELETE) {
      BlocProvider.of<TestimoniesBloc>(context)
        ..add(MyTestimonyDeleted(id: menuButtonValue.id));
    } else if (menuButtonValue.action == TestimonyActionOptions.REPORT) {
      BlocProvider.of<AllTestimoniesBloc>(context)
        ..add(TestimonyReported(id: menuButtonValue.id));
    } else if (menuButtonValue.action == TestimonyActionOptions.MY_CLOSE) {
      BlocProvider.of<TestimoniesBloc>(context)
        ..add(CloseTestimony(id: menuButtonValue.id));
    }
  }

  List<PopupMenuItem> getTestimonyCardMenuItems(Testimony testimony) {
    List<PopupMenuItem> popupMenuItems = [];

    if (testimony.isMine) {
      popupMenuItems.add(PopupMenuItem(
        value: MenuButtonValue(
            id: testimony.id, action: TestimonyActionOptions.MY_DELETE),
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
      if (!testimony.isAnswered) {
        popupMenuItems.add(PopupMenuItem(
          value: MenuButtonValue(
              id: testimony.id, action: TestimonyActionOptions.MY_CLOSE),
          child: Row(
            children: [
              Icon(
                Icons.check,
                size: getIt<LayoutFactory>().getDimension(baseDimension: 24.0),
              ),
              SizedBox(width: 4),
              Expanded(
                child: getIt<TextFactory>().lite('ARCHIVE'),
              )
            ],
          ),
        ));
      }
    } else {
      popupMenuItems.add(PopupMenuItem(
        value: MenuButtonValue(
            id: testimony.id, action: TestimonyActionOptions.REPORT),
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

class TestimoniesUserAndDate extends StatelessWidget {
  final Testimony testimony;

  const TestimoniesUserAndDate({Key? key, required this.testimony})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Container(
            height: 30,
            width: 30,
            child: (testimony.isAnonymous ||
                    testimony.userSnippet.thumbnailUrl == null)
                ? Image.asset(kProfilePhotoPlaceholder)
                : FadeInImage.assetNetwork(
                    fit: BoxFit.cover,
                    placeholder: kProfilePhotoPlaceholder,
                    image: testimony.userSnippet.thumbnailUrl!,
                  ),
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            () {
              if (testimony.isAnonymous) {
                return getIt<TextFactory>().regular("Anonymous");
              } else {
                return getIt<TextFactory>().regular(
                    '${testimony.userSnippet.firstName} ${testimony.userSnippet.lastName}');
              }
            }(),
            getIt<TextFactory>()
                .lite(toReadableDate(testimony.date), fontSize: 10.0)
          ],
        )
      ],
    );
  }
}

class PraiseButton extends StatelessWidget {
  final Testimony testimony;

  const PraiseButton({Key? key, required this.testimony}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _PraiseButton(
      testimony: testimony,
    );
  }
}

class _PraiseButton extends StatelessWidget {
  final Testimony testimony;

  const _PraiseButton({Key? key, required this.testimony}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllTestimoniesBloc, TestimoniesState>(
      builder: (BuildContext context, TestimoniesState state) {
        if (testimony.hasPraised) {
          return _createPraisedButton();
        } else if (state is PraiseTestimonyComplete) {
          if (state.id == testimony.id) {
            return _createPraisedButton();
          }
        } else if (state is PraiseTestimonyLoading) {
          if (state.id == testimony.id) {
            return _createLoadingButton();
          }
        }
        return _createPraiseButton(context);
      },
    );
  }

  Widget _createPraiseButton(BuildContext context) {
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
            BlocProvider.of<AllTestimoniesBloc>(context).add(PraiseTestimony(
              id: testimony.id,
            ));
          },
          child: getIt<TextFactory>().regular('PRAISE'),
        ),
      ),
    );
  }

  Widget _createPraisedButton() {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size(0, 24),
        padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: null,
      child: getIt<TextFactory>().regular('PRAISED!', color: Colors.black54),
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

class PraisedByIndicator extends StatelessWidget {
  final int amount;

  const PraisedByIndicator({Key? key, required this.amount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
          minimumSize: Size(0, 24),
          padding: EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      onPressed: null,
      child: getIt<TextFactory>().regular(
          'Prasied by $amount other${getS(amount)}',
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
  final TestimonyActionOptions action;

  MenuButtonValue({required this.id, required this.action});
}
