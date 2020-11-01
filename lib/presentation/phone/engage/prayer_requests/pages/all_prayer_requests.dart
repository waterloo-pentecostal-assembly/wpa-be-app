import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../../../constants.dart';
import '../../../../../domain/prayer_requests/entities.dart';
import '../../../../common/loader.dart';
import '../widgets/prayer_request_card.dart';
import '../widgets/prayer_request_card_placeholder.dart';
import '../widgets/prayer_request_error.dart';
import 'prayer_requests.dart';

class AllPrayerRequests extends StatefulWidget {
  @override
  _AllPrayerRequestsState createState() => _AllPrayerRequestsState();
}

class _AllPrayerRequestsState extends State<AllPrayerRequests> with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _scrollThreshold = 200.0;
  bool _isEndOfList = false;
  bool _moreRequested = false;

  _AllPrayerRequestsState() {
    _scrollController.addListener(_onScroll);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<AllPrayerRequestsBloc, PrayerRequestsState>(
      listener: (context, state) {},
      builder: (BuildContext context, PrayerRequestsState state) {
        return Scaffold(
          body: SafeArea(
            child: Container(
              // child: prayerRequestBody(state),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  prayerRequestBody(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget prayerRequestBody(PrayerRequestsState state) {
    if (state is PrayerRequestsLoaded) {
      this._isEndOfList = state.isEndOfList;
      if (_moreRequested) {
        _moreRequested = false; // Reset _moreRequested flag
      }
      return PrayerRequestsListBuilder(
        prayerRequests: state.prayerRequests,
        scrollController: _scrollController,
        isEndOfList: state.isEndOfList,
      );
    } else if (state is PrayerRequestsError) {
      return PrayerRequestsErrorWidget(message: state.message);
    }
    return Loader();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final int amount = calculateFetchAmount(context);

    if (maxScroll - currentScroll <= _scrollThreshold && !_isEndOfList && !_moreRequested) {
      context.bloc<AllPrayerRequestsBloc>().add(MorePrayerRequestsRequested(amount: amount));
      _moreRequested = true; // Set _moreRequested flag
    }
  }
}

class PrayerRequestsListBuilder extends StatelessWidget {
  final ScrollController scrollController;
  final List<PrayerRequest> prayerRequests;
  final bool isEndOfList;

  const PrayerRequestsListBuilder({
    Key key,
    @required this.scrollController,
    @required this.prayerRequests,
    @required this.isEndOfList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int amount = calculateFetchAmount(context);
    return Expanded(
      child: RefreshIndicator(
        color: kWpaBlue,
        onRefresh: () async {
          BlocProvider.of<AllPrayerRequestsBloc>(context).add(PrayerRequestsRequested(amount: amount));
        },
        child: ListView.builder(
          physics: AlwaysScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return index >= prayerRequests.length
                ? PrayerRequestCardPlaceholder()
                : PrayerRequestCard(prayerRequest: prayerRequests[index]);
          },
          itemCount: isEndOfList ? prayerRequests.length : prayerRequests.length,
          controller: scrollController,
        ),
      ),
    );
  }
}
