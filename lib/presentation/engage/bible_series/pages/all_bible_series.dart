import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';

import '../../../../app/constants.dart';
import '../../../../app/injection.dart';
import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../common/date_formatter.dart';
import '../../../common/text_factory.dart';

class AllBibleSeriesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<BibleSeriesBloc>(
      create: (BuildContext context) =>
          getIt<BibleSeriesBloc>()..add(RecentBibleSeriesRequested(amount: 20)),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(kHeadingPadding),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back,
                        size: getIt<LayoutFactory>()
                            .getDimension(baseDimension: 24.0),
                      ),
                    ),
                    SizedBox(width: 8),
                    getIt<TextFactory>().subPageHeading('Bible Series'),
                  ],
                ),
              ),
              Expanded(
                child: BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
                  listener: (context, state) {},
                  builder: (context, state) {
                    if (state is RecentBibleSeries) {
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.bibleSeriesList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: BibleSeriesListCard(
                                bibleSeries: state.bibleSeriesList[index]),
                          );
                        },
                      );
                    } else if (state is FetchingBibleSeries) {
                      return Center(child: CircularProgressIndicator());
                    } else if (state is BibleSeriesError) {
                      return Center(child: Text(state.message));
                    }
                    return Container();
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class BibleSeriesListCard extends StatelessWidget {
  final BibleSeries bibleSeries;
  const BibleSeriesListCard({Key? key, required this.bibleSeries})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/bible_series',
            arguments: {'bibleSeriesId': bibleSeries.id});
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: getIt<LayoutFactory>().getDimension(baseDimension: 100),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Image.network(
                  bibleSeries.imageUrl,
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      getIt<TextFactory>().subHeading3(bibleSeries.title),
                      if (bibleSeries.subTitle.isNotEmpty) ...[
                        SizedBox(height: 4),
                        getIt<TextFactory>().lite(bibleSeries.subTitle),
                      ],
                      SizedBox(height: 4),
                      getIt<TextFactory>().liteSmall(
                          '${dateFormatter.timeStampToString(bibleSeries.startDate)} - ${dateFormatter.timeStampToString(bibleSeries.endDate)}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
