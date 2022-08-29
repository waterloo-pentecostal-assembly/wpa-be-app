import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/infrastructure/bible_series/bible_series_repository.dart';

import '../../../app/injection.dart';
import '../../../application/achievements/achievements_bloc.dart';
import '../../../application/bible_series/bible_series_bloc.dart';
import '../../../application/media/media_bloc.dart';
import '../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../domain/authentication/entities.dart';
import '../../common/interfaces.dart';
import '../../common/text_factory.dart';
import '../bible_series/pages/all_bible_series.dart';
import '../bible_series/pages/bible_series_detail.dart';
import '../bible_series/pages/series_content_detail.dart';
import '../prayer_requests/pages/prayer_requests.dart';
import 'widgets/media_widget.dart';
import 'widgets/progress_widget.dart';
import 'widgets/bible_series_widget.dart';
import 'widgets/prayer_request_widget.dart';

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
            // ..add(
            // TODO: dynamically calculate how much recent prayer requests to get
            // RecentPrayerRequestsRequested(amount: 10),
            // ),
            ),
        BlocProvider<AchievementsBloc>(
          create: (BuildContext context) => getIt<AchievementsBloc>()
            ..add(
              WatchAchievementsStarted(),
              // AchievementsRequested(),
            ),
        ),
        BlocProvider<MediaBloc>(
          create: (BuildContext context) => getIt<MediaBloc>()
            ..add(
              AvailableMediaRequested(),
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
                    getIt<FirebaseAnalytics>()
                        .logEvent(name: 'bible_series_viewed');
                    Map args = settings.arguments;
                    return BibleSeriesDetailPage(
                      bibleSeriesId: args['bibleSeriesId'],
                    );
                  case '/all_bible_series':
                    return AllBibleSeriesPage();
                  case '/prayer_requests':
                    return PrayerRequestsPage(tabIndex: 0);
                  case '/prayer_requests/mine':
                    return PrayerRequestsPage(tabIndex: 1);
                  case '/content_detail':
                    getIt<FirebaseAnalytics>()
                        .logEvent(name: 'engagement_viewed');
                    Map args = settings.arguments;
                    return ContentDetailPage(
                      seriesContentId: args['seriesContentId'],
                      bibleSeriesId: args['bibleSeriesId'],
                      getCompletionDetails: args['getCompletionDetails'],
                      seriesContentType: args['seriesContentType'],
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
    return Container(
      color: Colors.grey.shade100,
      child: SafeArea(
        child: Scaffold(
          body: Container(
            // TODO: Add pull to refresh here
            child: RefreshIndicator(
              onRefresh: () async {
                // TODO: determine number of recents to get based on screen size
                BlocProvider.of<AchievementsBloc>(context)
                  ..add(WatchAchievementsStarted());
                BlocProvider.of<BibleSeriesBloc>(context)
                  ..add(RecentBibleSeriesRequested(amount: 15));
                BlocProvider.of<PrayerRequestsBloc>(context)
                  ..add(RecentPrayerRequestsRequested(amount: 10));
                BlocProvider.of<MediaBloc>(context)
                  ..add(AvailableMediaRequested());
              },
              child: ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  HeaderWidget(),
                  ProgressWidget(),
                  SizedBox(height: 16.0),
                  RecentBibleSeriesWidget(),
                  SizedBox(height: 16.0),
                  RecentPrayerRequestsWidget(),
                  SizedBox(height: 16.0),
                  MediaWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> getEngagePageWidgets() {
  // we want to know if there is any active bible
  // series. This determines the order of the list

  return [
    HeaderWidget(),
    ProgressWidget(),
    SizedBox(height: 16.0),
    RecentBibleSeriesWidget(),
    SizedBox(height: 16.0),
    RecentPrayerRequestsWidget(),
    SizedBox(height: 16.0),
    MediaWidget(),
  ];
}

class HeaderWidget extends StatelessWidget {
  final LocalUser localUser = getIt<LocalUser>();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: getIt<TextFactory>().heading('Hello, ${localUser.firstName}!'),
      ),
    );
  }
}
