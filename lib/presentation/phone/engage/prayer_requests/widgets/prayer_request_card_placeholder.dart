import 'package:flutter/material.dart';

import '../../../../../constants.dart';

class PrayerRequestCardPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8.0),
      height: kAllPrayerRequestsCardHeight,
      width: 0.9 * MediaQuery.of(context).size.width,
      padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: kCardOverlayGrey,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 8.0,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 8),
          Row(
            children: [
              ClipOval(
                child: Container(
                  height: 30,
                  width: 30,
                  color: kCardGrey,
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.all(
                      Radius.circular(2),
                    ),
                    child: Container(
                      height: 10,
                      width: 60,
                      color: kCardGrey,
                    ),
                  ),
                  SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.all(
                      Radius.circular(2),
                    ),
                    child: Container(
                      height: 8,
                      width: 40,
                      color: kCardGrey,
                    ),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

