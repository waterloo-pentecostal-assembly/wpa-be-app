import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/admin/admin_bloc.dart';
import 'package:wpa_app/domain/prayer_requests/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/loader.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:wpa_app/presentation/admin/helper.dart';

class PrayerApprovalPage extends StatefulWidget {
  @override
  _PrayerApprovalPageState createState() => _PrayerApprovalPageState();
}

class _PrayerApprovalPageState extends State<PrayerApprovalPage> {
  final key = GlobalKey<AnimatedListState>();
  late List<PrayerRequest> prayerRequestCards;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is UnverifiedPrayerRequestsLoaded) {
          _initPrayerList(state.prayerRequests);
        }
      },
      builder: (BuildContext context, state) {
        if (prayerRequestCards.isNotEmpty) {
          return SafeArea(
              child: Scaffold(
                  body: RefreshIndicator(
            onRefresh: () async {
              BlocProvider.of<AdminBloc>(context)
                ..add(LoadUnverifiedPrayerRequests());
            },
            child: Column(
              children: [
                HeaderWidget(title: 'Prayer Request Approval'),
                Expanded(
                    child: AnimatedList(
                  key: key,
                  physics: AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  initialItemCount: prayerRequestCards.length,
                  itemBuilder: (context, index, animation) =>
                      buildItem(prayerRequestCards[index], index, animation),
                ))
              ],
            ),
          )));
        } else if (prayerRequestCards.isEmpty) {
          return SafeArea(
              child: Container(
            child: Scaffold(
              body: RefreshIndicator(
                onRefresh: () async {
                  BlocProvider.of<AdminBloc>(context)
                    ..add(LoadUnverifiedUsers());
                },
                child: Column(
                  children: [
                    HeaderWidget(title: 'Prayer Request Approval'),
                  ],
                ),
              ),
            ),
          ));
        } else {
          return Loader();
        }
      },
    );
  }

  Widget buildItem(
      PrayerRequest prayerRequest, int index, Animation<double> animation) {
    return prayerRequestCard(prayerRequest, index, animation);
  }

  void removeItem(int index) {
    setState(() {
      final item = prayerRequestCards.removeAt(index);
      key.currentState?.removeItem(
          index, (context, animation) => buildItem(item, index, animation));
    });
  }

  _initPrayerList(List<PrayerRequest> prayersList) {
    setState(() {
      prayerRequestCards = prayersList;
    });
  }

  Widget prayerRequestCard(
      PrayerRequest prayerRequest, int index, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Container(
          margin: const EdgeInsets.all(8.0),
          width: 0.9 * MediaQuery.of(context).size.width,
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
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
            children: [
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(8),
                child: getIt<TextFactory>().lite(prayerRequest.request),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        BlocProvider.of<AdminBloc>(context)
                          ..add(DeletePrayerRequest(prayerRequest.id));
                        removeItem(index);
                      },
                      child: Icon(
                        Icons.cancel,
                        color: kErrorColor.withOpacity(0.8),
                        size: getIt<LayoutFactory>()
                            .getDimension(baseDimension: 40.0),
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        BlocProvider.of<AdminBloc>(context)
                          ..add(ApprovePrayerRequest(prayerRequest.id));
                        removeItem(index);
                      },
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: kSuccessColor.withOpacity(0.8),
                        size: getIt<LayoutFactory>()
                            .getDimension(baseDimension: 40.0),
                      ),
                    ),
                  ],
                ),
              )
            ],
          )),
    );
  }
}
