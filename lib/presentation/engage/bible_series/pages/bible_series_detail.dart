import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/constants.dart';
import '../../../../app/injection.dart';
import '../../../../application/bible_series/bible_series_bloc.dart';
import '../../../../domain/bible_series/entities.dart';
import '../../../common/text_factory.dart';

class BibleSeriesDetailPage extends StatelessWidget {
  final String bibleSeriesId;

  const BibleSeriesDetailPage({Key key, @required this.bibleSeriesId})
      : super(key: key);

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

class _BibleSeriesState extends State<BibleSeriesWidget>
    with TickerProviderStateMixin {
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
          List<SeriesContentSnippet> snippet =
              state.bibleSeriesDetail.seriesContentSnippet;

          tabLength = state.bibleSeriesDetail.seriesContentSnippet.length;
          _tabController = new TabController(
              length: tabLength,
              vsync: this,
              initialIndex: _getInitialIndex(snippet));

          return Scaffold(
            body: Column(
              children: [
                Container(
                  child: Stack(
                    children: [
                      Container(
                        height: 0.35 * MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0.0, 2.0),
                              blurRadius: 6.0,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0),
                          ),
                          child: Image.network(
                            state.bibleSeriesDetail.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(kHeadingPadding),
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
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.transparent,
                  child: TabBar(
                    labelPadding: EdgeInsets.all(8),
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(),
                    indicatorSize: TabBarIndicatorSize.label,
                    unselectedLabelColor: Colors.black54,
                    labelColor: Colors.black87,
                    tabs: _buildContentTabs(
                        state.bibleSeriesDetail.seriesContentSnippet),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(0),
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
        } else if (state is BibleSeriesError) {
          return Scaffold(
              body: SafeArea(child: Text('Error: ${state.message}')));
        }
        return SeriesDetailPlaceholder();
      },
    );
  }
}

class SeriesDetailPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int amtOfCards = (MediaQuery.of(context).size.width / 70).ceil();
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0),
                ),
                child: Container(
                  height: 0.35 * MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.grey.shade200,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(kHeadingPadding),
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
              ),
            ],
          ),
          Container(
            height: 148,
            padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
            child: ListView.builder(
              padding: EdgeInsets.only(left: 16),
              scrollDirection: Axis.horizontal,
              itemCount: amtOfCards,
              itemBuilder: (context, index) => Container(
                width: 70,
                margin: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        height: 108,
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 0, bottom: 15),
            height: 60,
            child: Container(
              width: 0.9 * MediaQuery.of(context).size.width,
              padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _buildContentTabs(
    List<SeriesContentSnippet> seriesContentSnippets) {
  List<Widget> tabs = [];
  seriesContentSnippets.forEach((element) {
    tabs.add(
      Container(
        height: 108,
        width: 70,
        child: Tab(
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _getStatusColor(
                  element.isCompleted, element.isDraft, element.date),
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
                  _getTodayIndicator(element.date),
                  getIt<TextFactory>().regular('${_getMonth(element.date)}'),
                  SizedBox(height: 3),
                  getIt<TextFactory>().heading('${_getDate(element.date)}'),
                  SizedBox(height: 3),
                  _getStatusIndicator(element.isCompleted, element.isDraft)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  });
  return tabs;
}

List<Widget> _buildContentChildren(
  BuildContext context,
  List<SeriesContentSnippet> seriesContentSnippets,
  String bibleSeriesId,
) {
  List<Widget> contentChildren = [];
  seriesContentSnippets.forEach((_element) {
    List<Widget> listChildren = [];

    _element.availableContentTypes.forEach((element) {
      listChildren.add(
        Container(
          margin: EdgeInsets.only(top: 0, bottom: 15),
          height: 60,
          child: Tab(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/content_detail', arguments: {
                  'bibleSeriesId': bibleSeriesId,
                  'seriesContentId': element.contentId,
                  'getCompletionDetails':
                      element.isCompleted || element.isDraft,
                  'seriesContentType': element.seriesContentType,
                }).then((value) => {onGoBack(context, bibleSeriesId)});
              },
              child: Container(
                width: 0.9 * MediaQuery.of(context).size.width,
                padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8.0,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      getIt<TextFactory>().subHeading(
                          element.seriesContentType.toString().split('.')[1]),
                      _getStatusIndicator(element.isCompleted, element.isDraft)
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });

    contentChildren.add(
      ListView(
        children: listChildren,
        padding: EdgeInsets.only(top: 20),
      ),
    );
  });
  return contentChildren;
}

String _getMonth(Timestamp date) {
  List<String> months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC'
  ];
  int monthNumber = int.parse(date.toDate().toString().substring(5, 7)) - 1;
  return months[monthNumber];
}

String _getDate(Timestamp date) {
  return date.toDate().toString().substring(8, 10);
}

Text _getTodayIndicator(Timestamp date) {
  String today = DateTime.now().toString().substring(0, 10);
  String d = date.toDate().toString().substring(0, 10);
  if (today == d) {
    return Text('•');
  }
  return Text('');
}

Widget _getStatusIndicator(bool isCompleted, bool isDraft) {
  if (isCompleted) {
    return Icon(Icons.done, size: 15);
  } else if (isDraft) {
    return Icon(Icons.edit, size: 15);
  }
  return Text('');
}

Color _getStatusColor(bool isCompleted, bool isDraft, Timestamp date) {
  if (isCompleted) {
    return Colors.green.withOpacity(0.25);
  } else if (isDraft) {
    return Colors.grey.shade100;
  } else if (date
          .toDate()
          .isBefore(DateTime.now().subtract(Duration(days: 1))) &&
      !isCompleted) {
    return Colors.amber.withOpacity(0.25);
  }
  return Colors.grey.shade100;
}

int _getInitialIndex(List<SeriesContentSnippet> snippet) {
  String today = DateTime.now().toString().substring(0, 10);
  for (SeriesContentSnippet element in snippet) {
    String date = element.date.toDate().toString().substring(0, 10);
    if (today == date) {
      return snippet.indexOf(element);
    }
  }
  return 0;
}

FutureOr onGoBack(BuildContext context, String bibleSeriesId) {
  BlocProvider.of<BibleSeriesBloc>(context)
    ..add(BibleSeriesDetailRequested(bibleSeriesId: bibleSeriesId));
}
