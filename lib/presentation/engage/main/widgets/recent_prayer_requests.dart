import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          color: Colors.grey.shade200,
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
              // () {
              //   if (state is RecentPrayerRequestsLoaded) {
              //     return
              Container(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey[500],
                              offset: Offset(4.0, 4.0),
                              blurRadius: 15.0,
                              spreadRadius: 1.0,
                            ),
                            BoxShadow(
                              color: Colors.white,
                              offset: Offset(-4.0, -4.0),
                              blurRadius: 15.0,
                              spreadRadius: 1.0,
                            )
                          ]),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/prayer_requests');
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              //padding: const EdgeInsets.only(left: 3), //
                              child: Icon(
                                Icons.remove_red_eye_rounded,
                                size: 40,
                              ),
                            ),
                            Center(
                              child: getIt<TextFactory>().lite("View All"),
                            )
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey[500],
                              offset: Offset(4.0, 4.0),
                              blurRadius: 15.0,
                              spreadRadius: 1.0,
                            ),
                            BoxShadow(
                              color: Colors.white,
                              offset: Offset(-4.0, -4.0),
                              blurRadius: 15.0,
                              spreadRadius: 1.0,
                            )
                          ]),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/prayer_requests');
                          OverlayEntry entry;
                          Overlay.of(context).insert(
                            entry = OverlayEntry(
                              builder: (context) {
                                return NewPrayerRequestForm(entry: entry);
                              },
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              //padding: const EdgeInsets.only(left: 3), //
                              child: Icon(
                                Icons.post_add_rounded,
                                size: 40,
                              ),
                            ),
                            Center(
                              child: getIt<TextFactory>().lite("Add New"),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // return Text(state.prayerRequests.toString());
              // return Text('Requests Loaded -  time to syle!');
              // return Container(
              //   height: 130,
              //   child: ListView.builder(
              //     // scrollDirection: Axis.vertical,
              //     scrollDirection: Axis.horizontal,
              //     // physics: NeverScrollableScrollPhysics(),
              //     // shrinkWrap: true,
              //     padding: EdgeInsets.only(left: 16),
              //     itemCount: state.prayerRequests.length,
              //     itemBuilder: (context, index) => PrayerRequestCard(
              //       prayerRequest: state.prayerRequests[index],
              //       prayButtonOrIndicator: PrayButton(),
              //       clearOrMenuButton: PrayerRequestMenuButton(),
              //     ),
              //   ),
              // );
              //   } else if (state is PrayerRequestsError) {
              //     return RecentPrayerRequestsError(
              //       errorMessage: state.message,
              //     );
              //   }
              //   return RecentPrayerRequestsPlaceholder();
              // }(),
            ],
          ),
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

  const RecentPrayerRequestsError({Key key, this.errorMessage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Prayer Requests Error: $errorMessage'),
    );
  }
}
