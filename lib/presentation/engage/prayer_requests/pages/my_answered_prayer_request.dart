import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/prayer_requests/prayer_requests_bloc.dart';
import 'package:wpa_app/domain/prayer_requests/entities.dart';
import 'package:wpa_app/presentation/common/loader.dart';
import 'package:wpa_app/presentation/engage/prayer_requests/widgets/prayer_request_card.dart';
import 'package:wpa_app/presentation/engage/prayer_requests/widgets/prayer_request_error.dart';

class MyAnsweredPrayerRequest extends StatefulWidget {
  @override
  _MyAnsweredPrayerRequestState createState() =>
      _MyAnsweredPrayerRequestState();
}

class _MyAnsweredPrayerRequestState extends State<MyAnsweredPrayerRequest>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<AnimatedListState> _myPrayerRequestsListKey =
      GlobalKey<AnimatedListState>();
  List<PrayerRequest> _prayerRequests;
  Widget _child = Loader();

  @override
  bool get wantKeepAlive => true;

  void setChild(Widget child) {
    setState(() {
      _child = child;
    });
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    Widget prayButtonOrIndicator;
    if (_prayerRequests[index].isApproved) {
      prayButtonOrIndicator =
          PrayedByIndicator(amount: _prayerRequests[index].prayedBy.length);
    } else {
      prayButtonOrIndicator = PendingIndicator();
    }
    return PrayerRequestCard(
      animation: animation,
      prayerRequest: _prayerRequests[index],
      prayButtonOrIndicator: prayButtonOrIndicator,
    );
  }

  Widget _buildDeletedItem(BuildContext context, PrayerRequest prayerRequest,
      Animation<double> animation) {
    Widget prayButtonOrIndicator;
    if (prayerRequest.isApproved) {
      prayButtonOrIndicator =
          PrayedByIndicator(amount: prayerRequest.prayedBy.length);
    } else {
      prayButtonOrIndicator = PendingIndicator();
    }
    return PrayerRequestCard(
      animation: animation,
      prayerRequest: prayerRequest,
      prayButtonOrIndicator: prayButtonOrIndicator,
    );
  }

  void _insertAtTop(PrayerRequest prayerRequest) {
    _prayerRequests.insert(0, prayerRequest);
    _myPrayerRequestsListKey.currentState.insertItem(0);
  }

  void _delete(int indexToDelete) {
    PrayerRequest deletedPrayerRequest =
        _prayerRequests.removeAt(indexToDelete);
    _myPrayerRequestsListKey.currentState.removeItem(
      indexToDelete,
      (context, animation) =>
          _buildDeletedItem(context, deletedPrayerRequest, animation),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<PrayerRequestsBloc, PrayerRequestsState>(
          listener: (context, state) {
            if (state is MyPrayerRequestDeleteComplete) {
              int indexToDelete = getIndexToDelete(state.id);
              if (indexToDelete != null) {
                _delete(indexToDelete);
              }
            } else if (state is MyPrayerRequestAnsweredComplete) {
              _insertAtTop(state.prayerRequest);
            }
          },
        ),
        BlocListener<MyAnsweredPrayerRequestsBloc, PrayerRequestsState>(
          listener: (context, state) {
            if (state is MyAnsweredPrayerRequestsLoaded) {
              _prayerRequests = state.prayerRequests;
              setChild(createPrayerRequestAnimatedlist(state));
            } else if (state is PrayerRequestsError) {
              setChild(PrayerRequestsErrorWidget(message: state.message));
            }
          },
        )
      ],
      child: _child,
    );
  }

  int getIndexToDelete(String id) {
    int indexToDelete;
    for (PrayerRequest prayerRequest in _prayerRequests) {
      int index = _prayerRequests.indexOf(prayerRequest);
      if (prayerRequest.id == id) {
        indexToDelete = index;
        break;
      }
    }
    return indexToDelete;
  }

  Widget createPrayerRequestAnimatedlist(MyAnsweredPrayerRequestsLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        BlocProvider.of<MyAnsweredPrayerRequestsBloc>(context)
          ..add(MyAnsweredPrayerRequestsRequested());
      },
      child: AnimatedList(
        physics: AlwaysScrollableScrollPhysics(),
        key: _myPrayerRequestsListKey,
        initialItemCount: state.prayerRequests.length,
        itemBuilder: _buildItem,
      ),
    );
  }
}
