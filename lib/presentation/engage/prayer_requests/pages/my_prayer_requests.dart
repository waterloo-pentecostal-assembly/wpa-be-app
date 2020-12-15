import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../../domain/prayer_requests/entities.dart';
import '../../../common/loader.dart';
import '../widgets/prayer_request_card.dart';
import '../widgets/prayer_request_error.dart';

class MyPrayerRequests extends StatefulWidget {
  @override
  _MyPrayerRequestsState createState() => _MyPrayerRequestsState();
}

class _MyPrayerRequestsState extends State<MyPrayerRequests> with AutomaticKeepAliveClientMixin {
  final GlobalKey<AnimatedListState> _myPrayerRequestsListKey = GlobalKey<AnimatedListState>();
  List<PrayerRequest> _prayerRequests;
  Widget _child = Loader();

  @override
  bool get wantKeepAlive => true;

  void setChild(Widget child) {
    setState(() {
      _child = child;
    });
  }

  Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
    return PrayerRequestCard(
      animation: animation,
      prayerRequest: _prayerRequests[index],
      prayButtonOrIndicator: PrayedByIndicator(amount: _prayerRequests[index].prayedBy.length),
    );
  }

  Widget _buildDeletedItem(BuildContext context, PrayerRequest prayerRequest, Animation<double> animation) {
    return PrayerRequestCard(
      animation: animation,
      prayerRequest: prayerRequest,
      prayButtonOrIndicator: PrayedByIndicator(amount: prayerRequest.prayedBy.length),
    );
  }

  void _insertAtTop(PrayerRequest prayerRequest) {
    _prayerRequests.insert(0, prayerRequest);
    _myPrayerRequestsListKey.currentState.insertItem(0);
  }

  void _delete(int indexToDelete) {
    PrayerRequest deletedPrayerRequest = _prayerRequests.removeAt(indexToDelete);
    _myPrayerRequestsListKey.currentState.removeItem(
      indexToDelete,
      (context, animation) => _buildDeletedItem(context, deletedPrayerRequest, animation),
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
            } else if (state is NewPrayerRequestLoaded) {
              _insertAtTop(state.prayerRequest);
            }
          },
        ),
        BlocListener<MyPrayerRequestsBloc, PrayerRequestsState>(
          listener: (context, state) {
            if (state is MyPrayerRequestsLoaded) {
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

  Widget createPrayerRequestAnimatedlist(MyPrayerRequestsLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        BlocProvider.of<MyPrayerRequestsBloc>(context)..add(MyPrayerRequestsRequested());
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

/* 
both:
  - my request deleted 
  - NewPrayerRequestLoaded

all 
  - requests requested 
  - request reported and removed 
  - more requests requested 

my 
  - my requests requested 
*/
