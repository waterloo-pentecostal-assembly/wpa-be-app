import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../domain/common/value_objects.dart';
import '../../../../injection.dart';

class ContentDetailPage extends StatelessWidget {
  final UniqueId seriesContentId;
  final UniqueId bibleSeriesId;
  final bool getCompletionDetails;

  const ContentDetailPage({
    Key key,
    @required this.seriesContentId,
    @required this.bibleSeriesId,
    @required this.getCompletionDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BibleSeriesBloc>(
          create: (BuildContext context) => getIt<BibleSeriesBloc>()
            ..add(
              ContentDetailRequested(
                seriesContentId: this.seriesContentId,
                bibleSeriesId: this.bibleSeriesId,
                getCompletionDetails: this.getCompletionDetails,
              ),
            ),
        ),
      ],
      child: ContentDetailWidget(),
    );
  }
}

class ContentDetailWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
      listener: (context, state) {},
      builder: (BuildContext context, BibleSeriesState state) {
        return SafeArea(
          child: Scaffold(
            body: Container(child: Text('Detail Page')),
          ),
        );
      },
    );
  }
}
