import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../../domain/prayer_requests/entities.dart';
import '../../../common/loader.dart';
import '../../../common/toast_message.dart';
import '../widgets/prayer_request_card.dart';
import '../widgets/prayer_request_error.dart';
import 'prayer_requests.dart';

class AllPrayerRequests extends StatefulWidget {
  @override
  _AllPrayerRequestsState createState() => _AllPrayerRequestsState();
}

class _AllPrayerRequestsState extends State<AllPrayerRequests>
    with AutomaticKeepAliveClientMixin {
  GlobalKey<AnimatedListState> _allPrayerRequestsListKey =
      GlobalKey<AnimatedListState>();
  final _scrollController = ScrollController();
  final _scrollThreshold = 200.0;
  bool _isEndOfList = false;
  bool _moreRequested = false;
  List<PrayerRequest> _prayerRequests;
  Widget _child = Loader();
  int _amountToFetch;

  _AllPrayerRequestsState() {
    _scrollController.addListener(_onScroll);
  }

  @override
  bool get wantKeepAlive => true;

  void setChild(Widget child) {
    setState(() {
      _child = child;
    });
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return PrayerRequestCard(
      prayerRequest: _prayerRequests[index],
      animation: animation,
      prayButtonOrIndicator: PrayButton(prayerRequest: _prayerRequests[index]),
    );
  }

  Widget _buildDeletedItem(
      BuildContext context, PrayerRequest item, Animation<double> animation) {
    return PrayerRequestCard(
      prayerRequest: item,
      animation: animation,
      prayButtonOrIndicator: PrayButton(prayerRequest: item),
    );
  }

  // ignore: unused_element
  void _insert(PrayerRequest prayerRequest) {
    _prayerRequests.insert(0, prayerRequest);
    _allPrayerRequestsListKey.currentState.insertItem(0);
  }

  void _addMany(List<PrayerRequest> prayerRequests) {
    int insertIndex = _prayerRequests.length - 1;
    _prayerRequests.addAll(prayerRequests);
    for (int offset = 0; offset < prayerRequests.length; offset++) {
      _allPrayerRequestsListKey.currentState.insertItem(insertIndex + offset);
    }
  }

  void _delete(int indexToDelete) {
    PrayerRequest deletedPrayerRequest =
        _prayerRequests.removeAt(indexToDelete);
    _allPrayerRequestsListKey.currentState.removeItem(
      indexToDelete,
      (context, animation) =>
          _buildDeletedItem(context, deletedPrayerRequest, animation),
    );
  }

  void _markAsPrayed(int index) {
    _prayerRequests[index].hasPrayed = true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _amountToFetch = calculateFetchAmount(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<PrayerRequestsBloc, PrayerRequestsState>(
          listener: (context, state) {
            // Handle states that are common to both
            if (state is NewPrayerRequestLoaded) {
              ToastMessage.showInfoToast(
                  'Request Submitted for Approval', context);
              // _insert(state.prayerRequest);
            } else if (state is MyPrayerRequestDeleteComplete) {
              int indexToDelete = getIndexById(state.id);
              if (indexToDelete != null) {
                _delete(indexToDelete);
              }
            } else if (state is NewPrayerRequestError) {
              ToastMessage.showErrorToast(state.message, context);
            } else if (state is PrayerRequestDeleteError) {
              ToastMessage.showErrorToast(state.message, context);
            }
            // No need to handle these two in MyPrayerRequests since this
            // BlocListener will be loaded in either case. If it is also
            // handled in MyPrayerRequests then two toasts will be shown
            // if the error was thron from MyPrayerRequests.
          },
        ),
        BlocListener<AllPrayerRequestsBloc, PrayerRequestsState>(
          // Handle states that are specific to all prayer requests
          listener: (context, state) {
            if (state is PrayerRequestsLoaded) {
              // Reset key on initial and subsequent loads.
              _allPrayerRequestsListKey = GlobalKey<AnimatedListState>();
              _isEndOfList = state.isEndOfList;
              _prayerRequests = state.prayerRequests;
              setChild(createPrayerRequestAnimatedlist());
            } else if (state is MorePrayerRequestsLoaded) {
              _isEndOfList = state.isEndOfList;
              _moreRequested = _moreRequested ? false : _moreRequested;
              _addMany(state.prayerRequests);
            } else if (state is PrayerRequestsError) {
              setChild(PrayerRequestsErrorWidget(message: state.message));
            } else if (state is PrayerRequestReportedAndRemoved) {
              int indexToDelete = getIndexById(state.id);
              if (indexToDelete != null) {
                _delete(indexToDelete);
              }
            } else if (state is PrayerRequestReportError) {
              ToastMessage.showErrorToast(state.message, context);
              // !!!! ONLY REMOVING AFTER 3 REPORTS ... AND ONE PERSON CAN REPORT MULTIPLE TIMES
            } else if (state is PrayForRequestComplete) {
              int index = getIndexById(state.id);
              _markAsPrayed(index);
            }
          },
        ),
      ],
      child: _child,
    );
  }

  int getIndexById(String id) {
    // O(n) ... not the best. Consider passing the index in the bloc event and getting it back in the state
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

  Widget createPrayerRequestAnimatedlist() {
    return RefreshIndicator(
      onRefresh: () async {
        BlocProvider.of<AllPrayerRequestsBloc>(context)
          ..add(PrayerRequestsRequested(amount: _amountToFetch));
      },
      child: AnimatedList(
        physics: AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        key: _allPrayerRequestsListKey,
        initialItemCount: _prayerRequests.length,
        itemBuilder: _buildItem,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final int amount = _amountToFetch;
    if (maxScroll - currentScroll <= _scrollThreshold &&
        !_isEndOfList &&
        !_moreRequested) {
      BlocProvider.of<AllPrayerRequestsBloc>(context)
        ..add(MorePrayerRequestsRequested(amount: amount));
      _moreRequested = true; // Set _moreRequested flag
    }
  }
}
