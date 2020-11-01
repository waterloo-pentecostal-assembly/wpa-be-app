import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/presentation/phone/engage/prayer_requests/widgets/my_prayer_request_card.dart';

import '../../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../../../domain/prayer_requests/entities.dart';
import '../../../../common/loader.dart';

final GlobalKey<AnimatedListState> myPrayerRequestsListKey = GlobalKey<AnimatedListState>();

class MyPrayerRequests extends StatefulWidget {
  @override
  _MyPrayerRequestsState createState() => _MyPrayerRequestsState();
}

class _MyPrayerRequestsState extends State<MyPrayerRequests> with AutomaticKeepAliveClientMixin {
  List<PrayerRequest> prayerRequests;
  Widget _child = Loader();

  @override
  bool get wantKeepAlive => true;

  void setChild(Widget child) {
    setState(() {
      _child = child;
    });
  }

  Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
    return _MyPrayerRequestCard(
      prayerRequest: prayerRequests[index],
      animation: animation,
    );
  }

  Widget _buildDeletedItem(BuildContext context, PrayerRequest item, Animation<double> animation) {
    return _MyPrayerRequestCard(
      prayerRequest: item,
      animation: animation,
    );
  }

  void _insert(PrayerRequest prayerRequest) {
    prayerRequests.insert(0, prayerRequest);
    myPrayerRequestsListKey.currentState.insertItem(0);
  }

  void _delete(int indexToDelete) {
    PrayerRequest deletedPrayerRequest = prayerRequests.removeAt(indexToDelete);
    myPrayerRequestsListKey.currentState.removeItem(
      indexToDelete,
      (context, animation) => _buildDeletedItem(context, deletedPrayerRequest, animation),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<MyPrayerRequestsBloc, PrayerRequestsState>(
      listener: (context, state) {
        if (state is MyPrayerRequestsLoaded) {
          prayerRequests = state.prayerRequests;
          setChild(
            AnimatedList(
              key: myPrayerRequestsListKey,
              initialItemCount: state.prayerRequests.length,
              itemBuilder: _buildItem,
            ),
          );
        } else if (state is PrayerRequestDeleteComplete) {
          int indexToDelete;
          for (PrayerRequest prayerRequest in prayerRequests) {
            int index = prayerRequests.indexOf(prayerRequest);
            if (prayerRequest.id == state.id) {
              indexToDelete = index;
              break;
            }
          }
          _delete(indexToDelete);
        } else if (state is NewPrayerRequestLoaded) {
          _insert(state.prayerRequest);
        }
      },
      child: _child,
    );
  }
}

class _MyPrayerRequestCard extends StatelessWidget {
  final PrayerRequest prayerRequest;
  final Animation<double> animation;

  const _MyPrayerRequestCard({Key key, @required this.prayerRequest, @required this.animation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MyPrayerRequestCard(prayerRequest: prayerRequest, animation: animation);
      // return FadeTransition(
      //   opacity: animation,
      //   child: GestureDetector(
      //     onTap: () {
      //       BlocProvider.of<MyPrayerRequestsBloc>(context)
      //         ..add(PrayerRequestDeleted(
      //           id: prayerRequest.id,
      //         ));
      //     },
      //     child: Container(
      //       height: 50,
      //       decoration: BoxDecoration(border: Border.all(color: Colors.amber)),
      //       child: Text(prayerRequest.request),
      //     ),
      //   ),
      // );
  }
}
