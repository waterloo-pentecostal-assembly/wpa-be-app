import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wpa_app/presentation/common/date_formatter.dart';

import '../../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../../app/constants.dart';
import '../../../../../domain/bible_series/entities.dart';
import '../../../../../app/injection.dart';
import '../../../common/text_factory.dart';

class RecentBibleSeriesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
      listener: (BuildContext context, state) {},
      builder: (BuildContext context, state) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 24, top: 12, bottom: 12, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  getIt<TextFactory>().subHeading('Recent Bible Series'),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/all_bible_series'),
                    child: getIt<TextFactory>().regular('See all'),
                  ),
                ],
              ),
            ),
            () {
              if (state is RecentBibleSeries) {
                return RecentBibleSeriesList(bibleSeriesList: state.bibleSeriesList);
              } else {
                return RecentBibleSeriesListPlaceholder();
              }
            }()
          ],
        );
      },
    );
  }
}

class RecentBibleSeriesList extends StatelessWidget {
  final List<BibleSeries> bibleSeriesList;

  const RecentBibleSeriesList({Key key, @required this.bibleSeriesList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kRecentBibleSeriesTileHeight + kRecentBibleSeriesTileDescriptionHeight,
      child: ListView.builder(
        padding: EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        itemCount: bibleSeriesList.length,
        itemBuilder: (context, index) => BibleSeriesCard(
          bibleSeries: bibleSeriesList[index],
        ),
      ),
    );
  }
}

class BibleSeriesCard extends StatelessWidget {
  final BibleSeries bibleSeries;

  const BibleSeriesCard({Key key, @required this.bibleSeries}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/bible_series', arguments: {'bibleSeriesId': bibleSeries.id});
      },
      child: Container(
        width: kRecentBibleSeriesTileWidth,
        padding: EdgeInsets.only(
          right: 8,
          left: 8,
          top: 8,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              // child: FadeInImage.assetNetwork(placeholder: kWpaLogoLoc, image: bibleSeries.imageUrl),
              child: Image.network(
                bibleSeries.imageUrl,
                height: kRecentBibleSeriesTileHeight,
                fit: BoxFit.fill,
                frameBuilder: (BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
                  if (frame != null && frame >= 0) {
                    return child;
                  } else {
                    return BibleSeriesCardPlaceholder();
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: getIt<TextFactory>().regular(bibleSeries.title),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: getIt<TextFactory>().lite(
                  '${dateFormatter.timeStampToString(bibleSeries.startDate)} - ${dateFormatter.timeStampToString(bibleSeries.endDate)}'),
            ),
          ],
        ),
      ),
    );
  }
}

class BibleSeriesCardPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: kRecentBibleSeriesTileHeight,
      color: Colors.grey.shade200,
    );
  }
}

class RecentBibleSeriesListPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: kRecentBibleSeriesTileHeight,
      child: ListView.builder(
        padding: EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        itemCount: (MediaQuery.of(context).size.width / kRecentBibleSeriesTileWidth).ceil(),
        itemBuilder: (_, __) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: BibleSeriesCardPlaceholder(),
          );
        },
      ),
    );
  }
}
