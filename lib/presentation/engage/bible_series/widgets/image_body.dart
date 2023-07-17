import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/completions/completions_bloc.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/presentation/common/layout_factory.dart';
import 'package:wpa_app/presentation/common/loader.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

class ImageInputBodyWidget extends StatelessWidget {
  final ImageInputBody imageInputBody;
  final int contentNum;
  final CompletionDetails completionDetails;
  final String bibleSeriesId;
  final SeriesContent seriesContent;
  const ImageInputBodyWidget(
      {Key key,
      this.imageInputBody,
      this.contentNum,
      this.completionDetails,
      this.bibleSeriesId,
      this.seriesContent})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    BlocProvider.of<CompletionsBloc>(context)
      ..add(LoadResponses(completionDetails));
    return ImageInputBodyState(
      contentNum: contentNum,
      completionDetails: completionDetails,
      bibleSeriesId: bibleSeriesId,
      seriesContent: seriesContent,
    );
  }
}

class ImageInputBodyState extends StatefulWidget {
  final int contentNum;
  final CompletionDetails completionDetails;
  final String bibleSeriesId;
  final SeriesContent seriesContent;
  ImageInputBodyState(
      {Key key,
      @required this.contentNum,
      @required this.completionDetails,
      @required this.bibleSeriesId,
      @required this.seriesContent})
      : super(key: key);

  @override
  _ImageInputBodyState createState() => _ImageInputBodyState();
}

class _ImageInputBodyState extends State<ImageInputBodyState> {
  ImagePicker imagePicker = ImagePicker();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompletionsBloc, CompletionsState>(
      listener: (context, state) {},
      builder: (BuildContext context, CompletionsState state) {
        if (state.uploadTask != null &&
            state.uploadTask[widget.contentNum.toString()] != null) {
          return imageLoading(state.uploadTask[widget.contentNum.toString()]);
        } else if (state.downloadURL != null) {
          if (state.downloadURL[widget.contentNum.toString()] != null) {
            return imageLoaded(
                state, widget.completionDetails, widget.contentNum);
          }
        }

        return Column(
          children: [
            SizedBox(height: 4),
            Container(
              child: GestureDetector(
                child: Icon(
                  Icons.add_a_photo,
                  size:
                      getIt<LayoutFactory>().getDimension(baseDimension: 36.0),
                  color: Colors.black87.withOpacity(0.75),
                ),
                onTap: selectImageInput,
              ),
            ),
            SizedBox(height: 4),
            getIt<TextFactory>().lite('Upload Photo!'),
          ],
        );
      },
    );
  }

  void selectImageInput() async {
    PickedFile selected =
        await imagePicker.getImage(source: ImageSource.gallery);
    if (selected != null && selected.path != null) {
      BlocProvider.of<CompletionsBloc>(context)
        ..add(
          UploadImage(
            image: File(selected.path),
            contentNum: widget.contentNum,
            questionNum: 0,
            bibleSeriesId: widget.bibleSeriesId,
            seriesContent: widget.seriesContent,
          ),
        );
    }
  }

  Widget imageLoading(UploadTask uploadTask) {
    return StreamBuilder(
      stream: uploadTask.snapshotEvents,
      builder: (context, AsyncSnapshot<TaskSnapshot> snapshot) {
        int bytesTransferred = snapshot?.data?.bytesTransferred;
        int totalBytes = snapshot?.data?.totalBytes;
        int progressPercent = 0;

        if (bytesTransferred != null && totalBytes != null) {
          progressPercent = ((bytesTransferred / totalBytes) * 100).ceil();
        }
        return Container(
          padding: const EdgeInsets.all(16),
          child: Center(
              child: getIt<TextFactory>()
                  .regular('$progressPercent%', fontSize: 12)),
        );
      },
    );
  }

  Widget imageLoaded(CompletionsState state,
      CompletionDetails completionDetails, int contentNum) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              child: GestureDetector(
                onTap: () {
                  BlocProvider.of<CompletionsBloc>(context)
                    ..add(DeleteImage(
                      gsURL: state
                          .responses
                          .responses[widget.contentNum.toString()]['0']
                          .response,
                      completionDetails: completionDetails,
                      contentNum: contentNum,
                    ));
                },
                child: Center(
                  child: Icon(
                    Icons.close,
                    size: getIt<LayoutFactory>()
                        .getDimension(baseDimension: 30.0),
                  ),
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
            onTap: () {
              return showDialog(
                  context: context,
                  builder: (context) {
                    return WillPopScope(
                      onWillPop: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        return Future.value(false);
                      },
                      child: Stack(children: [
                        Center(
                          child: Container(
                            color: Colors.transparent,
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: MediaQuery.of(context).size.width * 1.6,
                            child: PhotoView(
                              backgroundDecoration:
                                  BoxDecoration(color: Colors.transparent),
                              imageProvider: NetworkImage(state
                                      .downloadURL[widget.contentNum.toString()]
                                  [0]),
                              minScale: PhotoViewComputedScale.contained * 0.8,
                              maxScale: PhotoViewComputedScale.covered * 2,
                              loadingBuilder: (context, event) => Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 30,
                          top: 30,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                            child: Center(
                              child: Icon(
                                Icons.close,
                                size: getIt<LayoutFactory>()
                                    .getDimension(baseDimension: 30.0),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    );
                  });
            },
            child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: imageWidget(state, contentNum.toString()))),
      ],
    );
  }
}

Widget imageWidget(CompletionsState state, String contentNum) {
  if (state.thumbnailURL != null && state.thumbnailURL[contentNum] != null) {
    return Image.network(
      state.thumbnailURL[contentNum][0],
      fit: BoxFit.fill,
    );
  } else if (state.localImage != null && state.localImage[contentNum] != null) {
    return Image.file(state.localImage[contentNum][0]);
  } else {
    return Loader();
  }
}
