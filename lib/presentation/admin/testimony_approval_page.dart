import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/admin/admin_bloc.dart';
import 'package:wpa_app/domain/testimonies/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/loader.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';
import 'package:wpa_app/presentation/admin/helper.dart';

class TestimonyApprovalPage extends StatefulWidget {
  @override
  _TestimonyApprovalPageState createState() => _TestimonyApprovalPageState();
}

class _TestimonyApprovalPageState extends State<TestimonyApprovalPage> {
  final key = GlobalKey<AnimatedListState>();
  List<Testimony> testimonyRequestCards = [];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is UnverifiedTestimoniesLoaded) {
          _initTestimonyList(state.testimonies);
        }
      },
      builder: (BuildContext context, state) {
        if (testimonyRequestCards.isNotEmpty) {
          return SafeArea(
              child: Scaffold(
                  body: RefreshIndicator(
            onRefresh: () async {
              BlocProvider.of<AdminBloc>(context)
                ..add(LoadUnverifiedTestimonies());
            },
            child: Column(
              children: [
                HeaderWidget(title: 'Testimony Request Approval'),
                Expanded(
                    child: AnimatedList(
                  key: key,
                  physics: AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  initialItemCount: testimonyRequestCards.length,
                  itemBuilder: (context, index, animation) =>
                      buildItem(testimonyRequestCards[index], index, animation),
                ))
              ],
            ),
          )));
        } else if (testimonyRequestCards.isEmpty) {
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
                    HeaderWidget(title: 'Testimony Request Approval'),
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
      Testimony testimonyRequest, int index, Animation<double> animation) {
    return testimonyRequestCard(testimonyRequest, index, animation);
  }

  void removeItem(int index) {
    setState(() {
      final item = testimonyRequestCards.removeAt(index);
      key.currentState?.removeItem(
          index, (context, animation) => buildItem(item, index, animation));
    });
  }

  _initTestimonyList(List<Testimony> testimonysList) {
    setState(() {
      testimonyRequestCards = testimonysList;
    });
  }

  Widget testimonyRequestCard(
      Testimony testimonyRequest, int index, Animation<double> animation) {
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
                child: getIt<TextFactory>().lite(testimonyRequest.request),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        BlocProvider.of<AdminBloc>(context)
                          ..add(DeleteTestimony(testimonyRequest.id));
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
                          ..add(ApproveTestimony(testimonyRequest.id));
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
