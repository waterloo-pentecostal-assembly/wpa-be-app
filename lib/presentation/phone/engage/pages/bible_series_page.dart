import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../domain/common/value_objects.dart';
import '../../../../injection.dart';
import '../../../common/loader.dart';

class BibleSeriesPage extends StatelessWidget {
  final UniqueId bibleSeriesId;

  const BibleSeriesPage({Key key, @required this.bibleSeriesId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BibleSeriesBloc>(
          create: (BuildContext context) => getIt<BibleSeriesBloc>()
            ..add(
              BibleSeriesInformationRequested(bibleSeriesId: this.bibleSeriesId),
            ),
        )
      ],
      child: BibleSeriesWidget(),
    );
  }
}

class BibleSeriesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (BuildContext context, BibleSeriesState state) {
        if (state is BibleSeriesInformation) {
          return Scaffold(
            body: SafeArea(
              child: Container(
                child: Column(
                  children: <Widget>[
                    Text('Bible Series Page. ID: ${state.bibleSeriesInformation}'),
                  ],
                ),
              ),
            ),
          );
        }
        return Loader();
      },
    );
  }
}