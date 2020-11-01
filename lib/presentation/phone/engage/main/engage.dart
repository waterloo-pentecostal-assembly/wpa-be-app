import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/achievements/achievements_bloc.dart';
import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../../injection.dart';
import '../../common/factories/text_factory.dart';
import '../../common/interfaces.dart';
import '../bible_series/pages/all_bible_series.dart';
import '../bible_series/pages/bible_series_detail.dart';
import '../bible_series/pages/series_content_detail.dart';
import '../prayer_requests/pages/prayer_requests.dart';
import 'widgets/recent_bible_series.dart';
import 'widgets/recent_prayer_requests.dart';
import 'widgets/streaks_widget.dart';

class EngagePage extends IIndexedPage {
  final GlobalKey<NavigatorState> navigatorKey;

  const EngagePage({Key key, this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BibleSeriesBloc>(
          create: (BuildContext context) => getIt<BibleSeriesBloc>()
            ..add(
              // TODO: dynamically calculate how much recent bible series to get
              RecentBibleSeriesRequested(amount: 3),
            ),
        ),
        BlocProvider<PrayerRequestsBloc>(
          create: (BuildContext context) => getIt<PrayerRequestsBloc>()
            ..add(
              // TODO: dynamically calculate how much recent prayer requests to get
              RecentPrayerRequestsRequested(amount: 10),
            ),
        ),
        BlocProvider<AchievementsBloc>(
          create: (BuildContext context) => getIt<AchievementsBloc>()
            ..add(
              AchievementsRequested(),
            ),
        ),
      ],
      child: Scaffold(
        body: Navigator(
          key: navigatorKey,
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute(
              settings: settings,
              builder: (BuildContext context) {
                switch (settings.name) {
                  case '/':
                    return EngageIndex();
                  case '/bible_series':
                    Map args = settings.arguments;
                    return BibleSeriesDetailPage(
                      bibleSeriesId: args['bibleSeriesId'],
                    );
                  case '/all_bible_series':
                    return AllBibleSeriesPage();
                  case '/prayer_requests':
                    return PrayerRequestsPage();
                  case '/content_detail':
                    Map args = settings.arguments;
                    return ContentDetailPage(
                      seriesContentId: args['seriesContentId'],
                      bibleSeriesId: args['bibleSeriesId'],
                      getCompletionDetails: args['getCompletionDetails'],
                    );
                }
                // Handles case where no routes match
                return EngageIndex();
              },
            );
          },
        ),
      ),
    );
  }
}

class EngageIndex extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          child: ListView(
            physics: ClampingScrollPhysics(),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 24, top: 16, bottom: 16),
                child: getIt<TextFactory>().heading('Engage'),
              ),
              StreaksWidget(),
              RecentBibleSeriesWidget(),
              SizedBox(
                height: 20.0,
              ),
              RecentPrayerRequestsWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
