import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/presentation/engage/prayer_requests/widgets/new_prayer_request.dart';

import '../../../../app/injection.dart';
import '../../../../application/prayer_requests/prayer_requests_bloc.dart';
import '../../../common/text_factory.dart';

class RecentPrayerRequestsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrayerRequestsBloc, PrayerRequestsState>(
      listener: (BuildContext context, state) {},
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
                    // GestureDetector(
                    //   child: getIt<TextFactory>().regular('See all'),
                    //   onTap: () =>
                    //       Navigator.pushNamed(context, '/prayer_requests'),
                    // ),
                  ],
                ),
              ),
              Container(
                height: kPrayerRequestButtonHeight,
                child: ListView(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/prayer_requests');
                      },
                      child: Container(
                        width: kPrayerRequestButtonWidth,
                        margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: getIt<TextFactory>().regular(
                                "VIEW ALL",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Center(
                              child: getIt<TextFactory>().regular(
                                "REQUESTS",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/prayer_requests/mine');
                      },
                      child: Container(
                        width: kPrayerRequestButtonWidth,
                        margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: getIt<TextFactory>().regular(
                                "VIEW MY",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Center(
                              child: getIt<TextFactory>().regular(
                                "REQUESTS",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/prayer_requests/mine');
                        OverlayEntry entry;
                        Overlay.of(context).insert(
                          entry = OverlayEntry(
                            builder: (context) {
                              return NewPrayerRequestForm(entry: entry);
                            },
                          ),
                        );
                      },
                      child: Container(
                        width: kPrayerRequestButtonHeight,
                        margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.all(Radius.circular(40)),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.grey.shade100,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16)
            ],
          ),
        );
      },
    );
  }
}
