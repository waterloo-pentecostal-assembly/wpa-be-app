import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../domain/bible_series/entities.dart';
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
              BibleSeriesDetailRequested(bibleSeriesId: this.bibleSeriesId),
            ),
        )
      ],
      child: BibleSeriesWidget(),
    );
  }
}

class BibleSeriesWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _BibleSeriesState();
}

class _BibleSeriesState extends State<BibleSeriesWidget> with SingleTickerProviderStateMixin {
  TabController _tabController;
  int tabLength;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
      listener: (context, state) {},
      builder: (BuildContext context, BibleSeriesState state) {
        if (state is BibleSeriesDetail) {
          tabLength = state.bibleSeriesDetail.seriesContentSnippet.length;
          _tabController = new TabController(length: tabLength, vsync: this);

          return Scaffold(
            body: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 0.8 * MediaQuery.of(context).size.width,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0), boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0.0, 2.0),
                          blurRadius: 6.0,
                        )
                      ]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30.0),
                        child: Image.network(
                          state.bibleSeriesDetail.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 40.0,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                            color: Colors.white,
                          )
                        ],
                      ),
                    )
                  ],
                ),
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: _buildContentTabs(state.bibleSeriesDetail.seriesContentSnippet),
                  ),
                ),
                Expanded(
                  child: Container(
                    child: TabBarView(
                      controller: _tabController,
                      children: _buildContentChildren(
                        context,
                        state.bibleSeriesDetail.seriesContentSnippet,
                        state.bibleSeriesDetail.id,
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        }
        return Loader();
      },
    );
  }
}

List<Tab> _buildContentTabs(List<SeriesContentSnippet> seriesContentSnippets) {
  List<Tab> tabs = [];
  seriesContentSnippets.forEach((element) {
    tabs.add(
      Tab(
        text:
            '''${element.date.toDate().toString().substring(0, 10)} - c: ${element.isCompleted} - d: ${element.isDraft} - ot: ${element.isOnTime}''',
      ),
    );
  });
  return tabs;
}

List<Widget> _buildContentChildren(
  BuildContext context,
  List<SeriesContentSnippet> seriesContentSnippets,
  UniqueId bibleSeriesId,
) {
  List<Widget> contentChildren = [];
  seriesContentSnippets.forEach((element) {
    List<Widget> listChildren = [];

    element.availableContentTypes.forEach((element) {
      listChildren.add(
        FlatButton(
          onPressed: () {
            Navigator.pushNamed(context, '/content_detail', arguments: {
              'bibleSeriesId': bibleSeriesId,
              'seriesContentId': element.contentId,
              'getCompletionDetails': false //TODO: remove hardcode
            });
          },
          child: Row(
            children: [
              Text(element.seriesContentType.toString().split('.')[1]),
              Text('c: ${element.isCompleted} - d: ${element.isDraft} - ot: ${element.isOnTime}'),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          ),
        ),
      );
    });

    contentChildren.add(
      ListView(
        children: listChildren,
      ),
    );
  });
  return contentChildren;
}
