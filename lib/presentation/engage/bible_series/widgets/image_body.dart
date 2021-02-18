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

        return Column(
          children: [
            SizedBox(height: 4),
            Container(
              child: GestureDetector(
                child: Icon(
                  Icons.add_a_photo,
                  size: 36,
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
          ),
        );
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
      },
    );
  }

  Widget imageLoaded(String downloadURL, CompletionDetails completionDetails,
      String gsURL, int contentNum) {
    print(NetworkImage(downloadURL).scale);
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
                      gsURL: gsURL,
                      completionDetails: completionDetails,
                      contentNum: contentNum,
                    ));
                },
                child: Center(
                  child: Icon(
                    Icons.close,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width,
          child: PhotoView(
            imageProvider: NetworkImage(downloadURL),
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration:
                BoxDecoration(color: Theme.of(context).canvasColor),
          ),
        ),
      ],
    );
  }
}
