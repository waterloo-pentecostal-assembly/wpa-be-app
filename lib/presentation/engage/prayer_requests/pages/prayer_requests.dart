import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/engage/prayer_requests/pages/my_answered_prayer_request.dart';

import '../../../../app/constants.dart';
import '../../../../app/injection.dart';
import '../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../common/text_factory.dart';
import '../widgets/new_prayer_request.dart';
import 'all_prayer_requests.dart';
import 'my_prayer_requests.dart';

class PrayerRequestsPage extends StatelessWidget {
  final int tabIndex;

  const PrayerRequestsPage({Key key, required this.tabIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int amount = calculateFetchAmount(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider<AllPrayerRequestsBloc>(
          create: (BuildContext context) => getIt<PrayerRequestsBloc>()
            ..add(PrayerRequestsRequested(amount: amount)),
        ),
        BlocProvider<MyPrayerRequestsBloc>(
          create: (BuildContext context) =>
              getIt<PrayerRequestsBloc>()..add(MyPrayerRequestsRequested()),
        ),
        BlocProvider<MyAnsweredPrayerRequestsBloc>(
          create: (BuildContext context) => getIt<PrayerRequestsBloc>()
            ..add(MyAnsweredPrayerRequestsRequested()),
        )
      ],
      child: Scaffold(
        body: SafeArea(
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrayerRequestsTitleBar(),
                TabPrayerRequestWidget(tabIndex: tabIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TabPrayerRequestWidget extends StatefulWidget {
  final int tabIndex;

  const TabPrayerRequestWidget({Key key, required this.tabIndex})
      : super(key: key);

  @override
  _TabPrayerRequestWidgetState createState() =>
      _TabPrayerRequestWidgetState(tabIndex);
}

class _TabPrayerRequestWidgetState extends State<TabPrayerRequestWidget>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  final int tabIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _TabPrayerRequestWidgetState(this.tabIndex);

  @override
  Widget build(BuildContext context) {
    _tabController.index = tabIndex;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 10),
            color: Colors.transparent,
            child: TabBar(
              labelPadding: EdgeInsets.all(8),
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(),
              indicatorSize: TabBarIndicatorSize.label,
              unselectedLabelColor: Colors.black54,
              labelColor: Colors.black87,
              tabs: [
                getIt<TextFactory>().subHeading2('All'),
                getIt<TextFactory>().subHeading2('My Open Requests'),
                getIt<TextFactory>().subHeading2('My Answered Prayers')
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  AllPrayerRequests(),
                  MyPrayerRequests(),
                  MyAnsweredPrayerRequest(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class PrayerRequestsTitleBar extends StatelessWidget {
  const PrayerRequestsTitleBar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kHeadingPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back,
                  size:
                      getIt<LayoutFactory>().getDimension(baseDimension: 24.0),
                ),
              ),
              SizedBox(width: 8),
              getIt<TextFactory>().subPageHeading('Prayer Requests'),
            ],
          ),
          GestureDetector(
            onTap: () {
              OverlayEntry entry;
              Overlay.of(context).insert(
                entry = OverlayEntry(
                  builder: (context) {
                    return NewPrayerRequestForm(entry: entry);
                  },
                ),
              );
            },
            child: ClipOval(
              child: Container(
                color: Colors.grey.shade300,
                child: Icon(Icons.add,
                    size: getIt<LayoutFactory>()
                        .getDimension(baseDimension: 24.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int calculateFetchAmount(context) {
  double availableSpace = MediaQuery.of(context).size.height;
  // 75 = Approximate min height of each card. This will ensure the screen is full on the intial load.
  return (availableSpace / 75).ceil() + 1;
}
