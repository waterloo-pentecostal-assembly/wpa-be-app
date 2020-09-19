import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../injection.dart';
import '../../common/factories/text_factory.dart';
import '../../common/interfaces.dart';
import '../widgets/recent_bible_series.dart';
import 'bible_series_page.dart';

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
              RecentBibleSeriesRequested(),
            ),
        )
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
                    return BibleSeriesPage(
                      bibleSeriesId: args['bibleSeriesId'],
                    );
                }
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
                padding: EdgeInsets.only(
                  left: 24,
                  top: 16,
                  bottom: 16,
                ),
                child: getIt<TextFactory>().heading('Engage'),
              ),
              RecentBibleSeriesWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
