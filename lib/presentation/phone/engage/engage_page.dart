import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/bible_series/bible_series_bloc.dart';
import '../../../injection.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../common/factories/text_factory.dart';
import 'widgets/recent_bible_series.dart';

class EngagePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BibleSeriesBloc>(
            create: (BuildContext context) =>
                getIt<BibleSeriesBloc>()..add(RequestRecentBibleSeries()))
      ],
      child: SafeArea(
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
      ),
    );
  }
}
