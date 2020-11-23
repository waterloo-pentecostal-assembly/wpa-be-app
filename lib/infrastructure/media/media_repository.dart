import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:wpa_app/infrastructure/common/firebase_storage_helper.dart';

import '../../domain/common/exceptions.dart';
import '../../domain/media/entities.dart';
import '../../domain/media/interfaces.dart';
import '../common/helpers.dart';
import 'media_dto.dart';

class MediaRepository implements IMediaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorageHelper _firebaseStorageHelper;
  CollectionReference _mediaCollection;

  MediaRepository(
    this._firestore,
    this._firebaseStorageHelper,
  ) {
    _mediaCollection = _firestore.collection("media");
  }

  @override
  Future<List<Media>> getAvailableMedia() async {
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _mediaCollection.get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }

    List<Media> mediaList = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      try {
        mediaList.add(await MediaDto.fromFirestore(doc).toDomain(_firebaseStorageHelper));
      } catch (e) {
        // Handle so that malformed documents in Firestore does not affect app
      }
    }

    return mediaList;
  }
}
