import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/application/testimonies/testimonies_bloc.dart';
import 'package:wpa_app/presentation/engage/testimonies/widgets/new_testimony.dart';

import '../../../../app/injection.dart';
import '../../../common/loader.dart';
import '../../../common/text_factory.dart';
import '../../testimonies/widgets/testimony_card.dart';
import 'add_card.dart';

class RecentTestimoniesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TestimoniesBloc, TestimoniesState>(
      listener: (BuildContext context, state) {},
      buildWhen: (previous, current) =>
          current is RecentTestimoniesLoaded || current is TestimoniesLoading,
      builder: (BuildContext context, state) {
        return Container(
          color: Colors.grey.shade100,
          child: Column(
            children: [
              Padding(
                padding:
                    EdgeInsets.only(left: 24, top: 12, bottom: 12, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    getIt<TextFactory>().subHeading('Testimonies'),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/testimonies');
                      },
                      child: getIt<TextFactory>().regular('View All'),
                    ),
                  ],
                ),
              ),
              _buildList(state, context),
              SizedBox(height: 16)
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(TestimoniesState state, BuildContext context) {
    if (state is RecentTestimoniesLoaded) {
      List<Widget> children = [];
      for (int i = 0; i < state.testimonies.length; i++) {
        children.add(
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            child: TestimonyCard(
              testimony: state.testimonies[i],
              praiseButtonOrIndicator:
                  PraiseButton(testimony: state.testimonies[i]),
              animation: AlwaysStoppedAnimation(1),
            ),
          ),
        );
      }
      children.add(
        AddCard(
          text: "Add Testimony",
          onTap: () {
            OverlayEntry? entry;
            Overlay.of(context).insert(
              entry = OverlayEntry(
                builder: (context) {
                  return NewTestimonyForm(entry: entry);
                },
              ),
            );
          },
        ),
      );

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    } else if (state is TestimoniesLoading) {
      return Container(
        height: 100,
        child: Center(child: Loader()),
      );
    }
    return Container();
  }
}
