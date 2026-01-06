import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wpa_app/presentation/engage/prayer_requests/widgets/new_prayer_request.dart';

import '../../../../app/injection.dart';
import '../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../common/text_factory.dart';
import '../../../common/loader.dart';
import '../../prayer_requests/widgets/prayer_request_card.dart';
import 'add_card.dart';

class RecentPrayerRequestsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrayerRequestsBloc, PrayerRequestsState>(
      listener: (BuildContext context, state) {},
      buildWhen: (previous, current) =>
          current is RecentPrayerRequestsLoaded ||
          current is PrayerRequestsLoading,
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
                    getIt<TextFactory>().subHeading('Prayer Requests'),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/prayer_requests');
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

  Widget _buildList(PrayerRequestsState state, BuildContext context) {
    if (state is RecentPrayerRequestsLoaded) {
      List<Widget> children = [];
      for (int i = 0; i < state.prayerRequests.length; i++) {
        children.add(
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            child: PrayerRequestCard(
              prayerRequest: state.prayerRequests[i],
              prayButtonOrIndicator:
                  PrayButton(prayerRequest: state.prayerRequests[i]),
              animation: AlwaysStoppedAnimation(1),
            ),
          ),
        );
      }
      children.add(
        AddCard(
          text: "Add Request",
          onTap: () {
            OverlayEntry? entry;
            Overlay.of(context).insert(
              entry = OverlayEntry(
                builder: (context) {
                  return NewPrayerRequestForm(entry: entry);
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
    } else if (state is PrayerRequestsLoading) {
      return Container(
        height: 100,
        child: Center(child: Loader()),
      );
    }
    return Container();
  }
}
