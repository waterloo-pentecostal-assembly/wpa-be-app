import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/testimonies/testimonies_bloc.dart';
import 'package:wpa_app/domain/testimonies/entities.dart';
import 'package:wpa_app/presentation/engage/testimonies/widgets/testimony_card.dart';
import 'package:wpa_app/presentation/engage/testimonies/widgets/testimony_error.dart';

import '../../../common/loader.dart';
import '../../../common/toast_message.dart';
import 'testimonies.dart';

class AllTestimonies extends StatefulWidget {
  @override
  _AllTestimoniesState createState() => _AllTestimoniesState();
}

class _AllTestimoniesState extends State<AllTestimonies>
    with AutomaticKeepAliveClientMixin {
  GlobalKey<AnimatedListState> _allTestimoniesListKey =
      GlobalKey<AnimatedListState>();
  final _scrollController = ScrollController();
  final _scrollThreshold = 200.0;
  bool _isEndOfList = false;
  bool _moreRequested = false;
  late List<Testimony> _testimonies;
  Widget _child = Loader();
  late int _amountToFetch;

  _AllTestimoniesState() {
    _scrollController.addListener(_onScroll);
  }

  @override
  bool get wantKeepAlive => true;

  void setChild(Widget child) {
    setState(() {
      _child = child;
    });
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return TestimonyCard(
      testimony: _testimonies[index],
      animation: animation,
      praiseButtonOrIndicator: PraiseButton(testimony: _testimonies[index]),
    );
  }

  Widget _buildDeletedItem(
      BuildContext context, Testimony item, Animation<double> animation) {
    return TestimonyCard(
      testimony: item,
      animation: animation,
      praiseButtonOrIndicator: PraiseButton(testimony: item),
    );
  }

  // ignore: unused_element
  void _insert(Testimony testimony) {
    _testimonies.insert(0, testimony);
    _allTestimoniesListKey.currentState?.insertItem(0);
  }

  void _addMany(List<Testimony> testimonies) {
    int insertIndex = _testimonies.length - 1;
    _testimonies.addAll(testimonies);
    for (int offset = 0; offset < testimonies.length; offset++) {
      _allTestimoniesListKey.currentState?.insertItem(insertIndex + offset);
    }
  }

  void _delete(int indexToDelete) {
    Testimony deletedTestimonies = _testimonies.removeAt(indexToDelete);
    _allTestimoniesListKey.currentState?.removeItem(
      indexToDelete,
      (context, animation) =>
          _buildDeletedItem(context, deletedTestimonies, animation),
    );
  }

  void _markAsPraised(int index) {
    _testimonies[index].hasPraised = true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _amountToFetch = calculateFetchAmount(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<TestimoniesBloc, TestimoniesState>(
          listener: (context, state) {
            // Handle states that are common to both
            if (state is NewTestimonyLoaded) {
              ToastMessage.showInfoToast('Testimony Submitted', context);
              // _insert(state.testimony);
            } else if (state is MyTestimonyDeleteComplete) {
              int indexToDelete = getIndexById(state.id);
              _delete(indexToDelete);
            } else if (state is NewTestimonyError) {
              ToastMessage.showErrorToast(state.message, context);
            } else if (state is TestimonyDeleteError) {
              ToastMessage.showErrorToast(state.message, context);
            } else if (state is MyTestimonyAnsweredComplete) {
              int indexToDelete = getIndexById(state.id);
              _delete(indexToDelete);
            }
            // No need to handle these two in MyTestimonies since this
            // BlocListener will be loaded in either case. If it is also
            // handled in MyTestimonies then two toasts will be shown
            // if the error was thron from MyTestimonies.
          },
        ),
        BlocListener<AllTestimoniesBloc, TestimoniesState>(
          // Handle states that are specific to all testimonies
          listener: (context, state) {
            if (state is TestimoniesLoaded) {
              // Reset key on initial and subsequent loads.
              _allTestimoniesListKey = GlobalKey<AnimatedListState>();
              _isEndOfList = state.isEndOfList;
              _testimonies = state.testimonies;
              setChild(createTestimoniesAnimatedlist());
            } else if (state is MoreTestimoniesLoaded) {
              _isEndOfList = state.isEndOfList;
              _moreRequested = _moreRequested ? false : _moreRequested;
              _addMany(state.testimonies);
            } else if (state is TestimoniesError) {
              setChild(TestimoniesErrorWidget(message: state.message));
            } else if (state is TestimonyReportedAndRemoved) {
              int indexToDelete = getIndexById(state.id);
              _delete(indexToDelete);
              String message = 'Testimony has been reported';
              ToastMessage.showInfoToast(message, context);
            } else if (state is TestimonyReportError) {
              ToastMessage.showErrorToast(state.message, context);
            } else if (state is PraiseTestimonyComplete) {
              int index = getIndexById(state.id);
              _markAsPraised(index);
            } else if (state is PraiseTestimonyError) {
              ToastMessage.showErrorToast(state.message, context);
            }
          },
        ),
      ],
      child: _child,
    );
  }

  int getIndexById(String id) {
    // O(n) ... not the best. Consider passing the index in the bloc event and getting it back in the state
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

  Widget createTestimoniesAnimatedlist() {
    return RefreshIndicator(
      onRefresh: () async {
        BlocProvider.of<AllTestimoniesBloc>(context)
          ..add(TestimoniesRequested(amount: _amountToFetch));
      },
      child: AnimatedList(
        physics: AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        key: _allTestimoniesListKey,
        initialItemCount: _testimonies.length,
        itemBuilder: _buildItem,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final int amount = _amountToFetch;
    if (maxScroll - currentScroll <= _scrollThreshold &&
        !_isEndOfList &&
        !_moreRequested) {
      BlocProvider.of<AllTestimoniesBloc>(context)
        ..add(MoreTestimoniesRequested(amount: amount));
      _moreRequested = true; // Set _moreRequested flag
    }
  }
}
