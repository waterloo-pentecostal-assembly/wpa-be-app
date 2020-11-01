import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../../../injection.dart';
import '../../../common/factories/text_factory.dart';

class RecentPrayerRequestsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrayerRequestsBloc, PrayerRequestsState>(
      listener: (BuildContext context, state) {},
      builder: (BuildContext context, state) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 24, top: 12, bottom: 12, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  getIt<TextFactory>().subHeading('Recent Prayer Requests'),
                  GestureDetector(
                    child: getIt<TextFactory>().regular('See all'),
                    onTap: () => Navigator.pushNamed(context, '/prayer_requests'),
                  ),
                ],
              ),
            ),
            () {
              if (state is RecentPrayerRequestsLoaded) {
                // return Text(state.prayerRequests.toString());
                return Text('Requests Loaded -  time to syle!');
              } else if (state is PrayerRequestsError) {
                return RecentPrayerRequestsError(
                  errorMessage: state.message,
                );
              }
              return RecentPrayerRequestsPlaceholder();
            }(),
          ],
        );
      },
    );
  }
}

class RecentPrayerRequestsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Recent Prayer Requests Loading'),
    );
  }
}

class RecentPrayerRequestsError extends StatelessWidget {
  final String errorMessage;

  const RecentPrayerRequestsError({Key key, this.errorMessage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Prayer Requests Error: $errorMessage'),
    );
  }
}
