import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/application/testimonies/testimonies_bloc.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/engage/testimonies/widgets/new_testimony.dart';

import '../../../../app/injection.dart';
import '../../../common/text_factory.dart';

class RecentTestimoniesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TestimoniesBloc, TestimoniesState>(
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
                    getIt<TextFactory>().subHeading('Testimonies'),
                  ],
                ),
              ),
              TestimonyOptions(),
              SizedBox(height: 16)
            ],
          ),
        );
      },
    );
  }
}

class TestimonyOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: getIt<LayoutFactory>()
          .getDimension(baseDimension: kTestimonyButtonHeight),
      child: Container(
        margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/testimonies');
                },
                child: Container(
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
                          "TESTIMONIES",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/testimonies/mine');
                },
                child: Container(
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
                          "TESTIMONIES",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/testimonies/mine');
                  OverlayEntry? entry;
                  Overlay.of(context).insert(
                    entry = OverlayEntry(
                      builder: (context) {
                        return NewTestimonyForm(entry: entry);
                      },
                    ),
                  );
                },
                child: Container(
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
            ),
          ],
        ),
      ),
    );
  }
}
