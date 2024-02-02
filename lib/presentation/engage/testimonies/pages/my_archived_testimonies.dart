import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/testimonies/testimonies_bloc.dart';
import 'package:wpa_app/domain/testimonies/entities.dart';
import 'package:wpa_app/presentation/common/loader.dart';
import 'package:wpa_app/presentation/engage/testimonies/widgets/testimony_card.dart';
import 'package:wpa_app/presentation/engage/testimonies/widgets/testimony_error.dart';

class MyArchivedTestimonies extends StatefulWidget {
  @override
  _MyArchivedTestimoniesState createState() => _MyArchivedTestimoniesState();
}

class _MyArchivedTestimoniesState extends State<MyArchivedTestimonies>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<AnimatedListState> _myTestimoniesListKey =
      GlobalKey<AnimatedListState>();
  late List<Testimony> _testimonies;
  Widget _child = Loader();

  @override
  bool get wantKeepAlive => true;

  void setChild(Widget child) {
    setState(() {
      _child = child;
    });
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    Widget praiseButtonOrIndicator;
    if (_testimonies[index].isApproved) {
      praiseButtonOrIndicator =
          PraisedByIndicator(amount: _testimonies[index].praisedBy.length);
    } else {
      praiseButtonOrIndicator = PendingIndicator();
    }
    return TestimonyCard(
      animation: animation,
      testimony: _testimonies[index],
      praiseButtonOrIndicator: praiseButtonOrIndicator,
    );
  }

  Widget _buildDeletedItem(
      BuildContext context, Testimony testimony, Animation<double> animation) {
    Widget praiseButtonOrIndicator;
    if (testimony.isApproved) {
      praiseButtonOrIndicator =
          PraisedByIndicator(amount: testimony.praisedBy.length);
    } else {
      praiseButtonOrIndicator = PendingIndicator();
    }
    return TestimonyCard(
      animation: animation,
      testimony: testimony,
      praiseButtonOrIndicator: praiseButtonOrIndicator,
    );
  }

  void _insertAtTop(Testimony testimony) {
    _testimonies.insert(0, testimony);
    _myTestimoniesListKey.currentState?.insertItem(0);
  }

  void _delete(int indexToDelete) {
    Testimony deletedTestimonies = _testimonies.removeAt(indexToDelete);
    _myTestimoniesListKey.currentState?.removeItem(
      indexToDelete,
      (context, animation) =>
          _buildDeletedItem(context, deletedTestimonies, animation),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<TestimoniesBloc, TestimoniesState>(
          listener: (context, state) {
            if (state is MyTestimonyDeleteComplete) {
              int indexToDelete = getIndexToDelete(state.id);
              _delete(indexToDelete);
            } else if (state is MyTestimonyAnsweredComplete) {
              _insertAtTop(state.testimony);
            }
          },
        ),
        BlocListener<MyArchivedTestimoniesBloc, TestimoniesState>(
          listener: (context, state) {
            if (state is MyArchivedTestimoniesLoaded) {
              _testimonies = state.testimonies;
              setChild(createTestimoniesAnimatedlist(state));
            } else if (state is TestimoniesError) {
              setChild(TestimoniesErrorWidget(message: state.message));
            }
          },
        )
      ],
      child: _child,
    );
  }

  int getIndexToDelete(String id) {
    int indexToDelete = -1;
    for (Testimony testimony in _testimonies) {
      int index = _testimonies.indexOf(testimony);
      if (testimony.id == id) {
        indexToDelete = index;
        break;
      }
    }
    return indexToDelete;
  }

  Widget createTestimoniesAnimatedlist(MyArchivedTestimoniesLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        BlocProvider.of<MyArchivedTestimoniesBloc>(context)
          ..add(MyArchivedTestimoniesRequested());
      },
      child: AnimatedList(
        physics: AlwaysScrollableScrollPhysics(),
        key: _myTestimoniesListKey,
        initialItemCount: state.testimonies.length,
        itemBuilder: _buildItem,
      ),
    );
  }
}
