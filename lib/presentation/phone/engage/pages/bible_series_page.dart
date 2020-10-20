import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../../domain/common/value_objects.dart';
import '../../../../injection.dart';
import '../../../common/constants.dart';
import '../../../common/loader.dart';
import '../../common/factories/text_factory.dart';

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
    final double _datesPosition = MediaQuery.of(context).size.width;
    final double _datesHeight = 200;

    return BlocConsumer<BibleSeriesBloc, BibleSeriesState>(
      listener: (context, state) {},
      builder: (BuildContext context, BibleSeriesState state) {
        if (state is BibleSeriesDetail) {
          tabLength = state.bibleSeriesDetail.seriesContentSnippet.length;
          _tabController = new TabController(length: tabLength, vsync: this);

          return Scaffold(
            body: Column(
              children: [
                Container(
                  // height: MediaQuery.of(context).size.width + _datesHeight / 2,
                  child: Stack(
                    children: [
                      Container(
                        height: 0.8 * MediaQuery.of(context).size.width,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0.0, 2.0),
                              blurRadius: 6.0,
                            )
                          ],
                        ),
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
                      ),
                      // Positioned(
                      //   top: 0.8 * _datesPosition - _datesHeight / 2,
                      //   right: 0,
                      //   left: 0,
                      //   height: _datesHeight,
                      //   // top: 0.5 * MediaQuery.of(context).size.height,
                      //   // top: 275.0,
                      //   child: Container(
                      //     // decoration: BoxDecoration(color: Theme.of(context).primaryColor,),
                      //     color: Colors.transparent,
                      //     child: TabBar(
                      //       controller: _tabController,
                      //       isScrollable: true,
                      //       indicator: BoxDecoration(borderRadius: BorderRadius.circular(50)),
                      //       indicatorSize: TabBarIndicatorSize.label,
                      //       unselectedLabelColor: Colors.redAccent,
                      //       labelColor: Colors.black,
                      //       tabs: _buildContentTabs(state.bibleSeriesDetail.seriesContentSnippet),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                Container(
                  // decoration: BoxDecoration(color: Theme.of(context).primaryColor,),
                  // color: Colors.blue,
                  decoration: BoxDecoration(
                    // border: Border.all(color: Colors.amber),
                    color: Colors.transparent,
                  ),

                  child: TabBar(
                    labelPadding: EdgeInsets.all(8),
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(borderRadius: BorderRadius.circular(50)),
                    indicatorSize: TabBarIndicatorSize.label,
                    unselectedLabelColor: Colors.black54,
                    labelColor: Colors.black87,
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

String _getMonth(Timestamp date) {
  List<String> months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  int monthNumber = int.parse(date.toDate().toString().substring(5, 7)) - 1;
  return months[monthNumber];
}

String _getDate(Timestamp date) {
  return date.toDate().toString().substring(8, 10);
}

Text _isTodayIndicator(Timestamp date) {
  String today = DateTime.now().toUtc().toString().substring(0, 10);
  String d = date.toDate().toUtc().toString().substring(0, 10);
  if (today == d) {
    return Text('•');
  }
  return Text('');
}

Color _getTabColor(SeriesContentSnippet seriesContentSnippet) {
  // if completed -> green
  if (seriesContentSnippet.isCompleted) {
    return Colors.green.withOpacity(0.3);
  } else if (!seriesContentSnippet.isCompleted) {
    return Colors.amber.withOpacity(0.3);
  }
  return Colors.grey;
  // if draft -> blue
  // if not completed and date passed -> amber
  // if not completed and date not passed -> white
}

List<Widget> _buildContentTabs(List<SeriesContentSnippet> seriesContentSnippets) {
  List<Widget> tabs = [];
  seriesContentSnippets.forEach((element) {
    print('${element.isCompleted} - d: ${element.isDraft} - ot: ${element.isOnTime}');
    tabs.add(
      Container(
        height: 90,
        width: 70,
        decoration: BoxDecoration(
            // border: Border.all(color: Colors.green),
            ),
        child: Tab(
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
            // margin: EdgeInsets.all(0.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              // border: Border.all(color: Colors.black),
              // color: kSuccessColor,
              color: _getTabColor(element),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5.0,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  _isTodayIndicator(element.date),
                  getIt<TextFactory>().regular('${_getMonth(element.date)}'),
                  // Text('${_getMonth(element.date)}'),
                  SizedBox(
                    height: 3,
                  ),
                  getIt<TextFactory>().heading('${_getDate(element.date)}'),
                  // Text(
                  //   '${_getDate(element.date)}',
                  //   style: TextStyle,
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Tab(
      //   text:
      //       '''${element.date.toDate().toString().substring(0, 10)} - c: ${element.isCompleted} - d: ${element.isDraft} - ot: ${element.isOnTime}''',
      // ),
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
