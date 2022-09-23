import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/presentation/common/loader.dart';

import '../../../domain/bible_series/interfaces.dart';
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
        // BlocProvider<BibleSeriesBloc>(
        //     create: (BuildContext context) => getIt<BibleSeriesBloc>()
        //       // ..add(HasActiveBibleSeriesRequested())
        //       ..add(
        //         // TODO: dynamically calculate how much recent bible series to get
        //         RecentBibleSeriesRequested(amount: 15),
        //       )),
        BlocProvider<BibleSeriesBloc>(
            create: (BuildContext context) =>
                getIt<BibleSeriesBloc>(instanceName: 'engage_page_layout')
                  ..add(HasActiveBibleSeriesRequested())
            // ..add(
            //   // TODO: dynamically calculate how much recent bible series to get
            //   RecentBibleSeriesRequested(amount: 15),
            // )
            ),
        BlocProvider<PrayerRequestsBloc>(
            create: (BuildContext context) => getIt<PrayerRequestsBloc>()),
        BlocProvider<AchievementsBloc>(
          create: (BuildContext context) => getIt<AchievementsBloc>()
            ..add(
              WatchAchievementsStarted(),
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
  const EngageIndex({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
      builder: (BuildContext context, BibleSeriesState state) {
        if (state is HasActiveBibleSeries) {
          List<Widget> children;
          if (state.hasActive) {
            children = <Widget>[
              HeaderWidget(),
              ProgressWidget(),
              SizedBox(height: 16.0),
              RecentBibleSeriesWidget(),
              SizedBox(height: 16.0),
              RecentPrayerRequestsWidget(),
              SizedBox(height: 16.0),
              MediaWidget(),
            ];
          } else {
            children = <Widget>[
              HeaderWidget(),
              SizedBox(height: 16.0),
              RecentBibleSeriesWidget(),
              SizedBox(height: 16.0),
              RecentPrayerRequestsWidget(),
              SizedBox(height: 16.0),
              MediaWidget(),
            ];
          }
          var parentContextBibleSeriesBloc =
              BlocProvider.of<BibleSeriesBloc>(context);
          return BlocProvider(
            create: (BuildContext context) {
              return getIt<BibleSeriesBloc>()
                ..add(
                  RecentBibleSeriesRequested(amount: 15),
                );
            },
            child: EngageLayoutWidget(
                parentContextBibleSeriesBloc: parentContextBibleSeriesBloc,
                children: children),
          );
        }
        return Loader();
      },
      listener: (BuildContext context, BibleSeriesState state) {},
    );
  }
}

class EngageLayoutWidget extends StatelessWidget {
  const EngageLayoutWidget({
    Key key,
    @required this.parentContextBibleSeriesBloc,
    @required this.children,
  }) : super(key: key);

  final BibleSeriesBloc parentContextBibleSeriesBloc;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        parentContextBibleSeriesBloc..add(HasActiveBibleSeriesRequested());
        BlocProvider.of<AchievementsBloc>(context)
          ..add(WatchAchievementsStarted());
        BlocProvider.of<BibleSeriesBloc>(context)
          ..add(RecentBibleSeriesRequested(amount: 15));
        BlocProvider.of<MediaBloc>(context)..add(AvailableMediaRequested());
      },
      child: Container(
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          children: children,
        ),
      ),
    );
  }
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
