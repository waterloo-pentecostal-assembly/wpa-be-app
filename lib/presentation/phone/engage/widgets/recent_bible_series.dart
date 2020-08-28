import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../../injection.dart';
import '../../common/factories/text_factory.dart';

class RecentBibleSeriesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
      listener: (BuildContext context, state) {
      },
      builder: (BuildContext context, state) {
        if (state is RecentBibleSeries) {
          return RecentBibleSeriesList(
            bibleSeriesList: state.bibleSeriesList,
          );
        }
        return RecentBibleSeriesLoading();
      },
    );
  }
}

class RecentBibleSeriesLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Loading'),
    );
  }
}

class RecentBibleSeriesList extends StatelessWidget {
  final List<BibleSeries> bibleSeriesList;

  const RecentBibleSeriesList({Key key, @required this.bibleSeriesList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(
            left: 24,
            top: 12,
            bottom: 12,
            right: 24,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              getIt<TextFactory>().subHeading('Recent Bible Series'),
              getIt<TextFactory>().regular('See all'),
            ],
          ),
        ),
        Container(
          height: 150,
          child: ListView.builder(
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: bibleSeriesList.length,
            itemBuilder: (context, index) => BibleSeriesCard(
              bibleSeries: bibleSeriesList[index],
            ),
          ),
        ),
      ],
    );
  }
}

class BibleSeriesCard extends StatelessWidget {
  final BibleSeries bibleSeries;

  const BibleSeriesCard({Key key, @required this.bibleSeries})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        right: 16,
        top: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 5,
            offset: Offset(0, 1), // changes position of shadow
          ),
        ],
      ),
      // NOTE consider using cached_network_image package here
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Image.network(
          bibleSeries.imageUrl,
        ),
      ),
    );
  }
}
