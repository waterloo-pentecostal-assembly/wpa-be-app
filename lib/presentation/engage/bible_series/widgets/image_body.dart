import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/completions/completions_bloc.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

//Used Stateful so that bloc and states can be implemented later
class ImageInputBodyWidget extends StatelessWidget {
  final ImageInputBody imageInputBody;
  final int contentNum;
  final CompletionDetails completionDetails;
  const ImageInputBodyWidget(
      {Key key, this.imageInputBody, this.contentNum, this.completionDetails})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    BlocProvider.of<CompletionsBloc>(context)
      ..add(LoadResponses(completionDetails));
    return ImageInputBodyState(
      contentNum: contentNum,
      completionDetails: completionDetails,
    );
  }
}

class ImageInputBodyState extends StatefulWidget {
  final int contentNum;
  final CompletionDetails completionDetails;
  ImageInputBodyState(
      {Key key, @required this.contentNum, @required this.completionDetails})
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
        if (state.uploadTask != null) {
          return imageLoading(state.uploadTask);
        } else if (state.downloadURL != null) {
          if (state.downloadURL[widget.contentNum.toString()] != null) {
            return imageLoaded(
                state.downloadURL[widget.contentNum.toString()],
                widget.completionDetails,
                state.responses.responses[widget.contentNum.toString()]['0']
                    .response,
                widget.contentNum);
          }
        }

        return Container(
          margin: const EdgeInsets.all(24),
          height: 80,
          width: 80,
          child: GestureDetector(
            child: Icon(
              Icons.add_a_photo,
              size: 40,
            ),
            onTap: selectImageInput,
          ),
          decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[600],
                  offset: Offset(2.0, 2.0),
                  blurRadius: 5.0,
                  spreadRadius: 1.0,
                ),
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(-2.0, -2.0),
                  blurRadius: 5.0,
                  spreadRadius: 1.0,
                )
              ],
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[200],
                    Colors.grey[300],
                    Colors.grey[400],
                    Colors.grey[500],
                  ],
                  stops: [
                    0.1,
                    0.3,
                    0.8,
                    1,
                  ])),
        );
      },
    );
  }

  void selectImageInput() async {
    PickedFile selected =
        await imagePicker.getImage(source: ImageSource.gallery);
    if (selected != null && selected.path != null) {
      BlocProvider.of<CompletionsBloc>(context)
        ..add(UploadImage(
            image: File(selected.path),
            contentNum: widget.contentNum,
            questionNum: 0));
    }
  }

  Widget imageLoading(UploadTask uploadTask) {
    return StreamBuilder(
        stream: uploadTask.snapshotEvents,
        builder: (context, AsyncSnapshot<TaskSnapshot> snapshot) {
          int bytesTransferred = snapshot?.data?.totalBytes;
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
        });
  }

  Widget imageLoaded(String downloadURL, CompletionDetails completionDetails,
      String gsURL, int contentNum) {
    return Column(
      children: [
        Container(
          child: Image.network(downloadURL),
        ),
        Container(
            child: GestureDetector(
                onTap: () {
                  BlocProvider.of<CompletionsBloc>(context)
                    ..add(DeleteImage(
                        gsURL: gsURL,
                        completionDetails: completionDetails,
                        contentNum: contentNum));
                },
                child: Center(
                    child: Icon(
                  Icons.cancel,
                  size: 50,
                  color: Colors.red,
                ))))
      ],
    );
  }
}
