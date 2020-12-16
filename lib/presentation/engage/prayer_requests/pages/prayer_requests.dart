import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/injection.dart';
import '../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../common/text_factory.dart';
import '../widgets/new_prayer_request.dart';
import 'all_prayer_requests.dart';
import 'my_prayer_requests.dart';

class PrayerRequestsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final int amount = calculateFetchAmount(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider<AllPrayerRequestsBloc>(
          create: (BuildContext context) => getIt<PrayerRequestsBloc>()..add(PrayerRequestsRequested(amount: amount)),
        ),
        BlocProvider<MyPrayerRequestsBloc>(
          create: (BuildContext context) => getIt<PrayerRequestsBloc>()..add(MyPrayerRequestsRequested()),
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrayerRequestsTitleBar(),
                TabPrayerRequestWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TabPrayerRequestWidget extends StatefulWidget {
  @override
  _TabPrayerRequestWidgetState createState() => _TabPrayerRequestWidgetState();
}

class _TabPrayerRequestWidgetState extends State<TabPrayerRequestWidget> with SingleTickerProviderStateMixin {
  TabController tabController;

  _TabPrayerRequestWidgetState() {
    this.tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.transparent,
            child: TabBar(
              labelPadding: EdgeInsets.all(8),
              controller: tabController,
              isScrollable: true,
              indicator: BoxDecoration(),
              indicatorSize: TabBarIndicatorSize.label,
              unselectedLabelColor: Colors.black54,
              labelColor: Colors.black87,
              tabs: [
                getIt<TextFactory>().subHeading2('All'),
                getIt<TextFactory>().subHeading2('Mine'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(0),
              child: TabBarView(
                controller: tabController,
                children: [
                  AllPrayerRequests(),
                  MyPrayerRequests(),
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
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back),
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
                height: 30,
                width: 30,
                color: Colors.grey.shade300,
                child: Icon(Icons.add),
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