import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../../domain/common/exceptions.dart';
import '../../domain/media/entities.dart';
import '../../domain/media/interfaces.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import 'media_dto.dart';

class MediaRepository implements IMediaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorageService _firebaseStorageService;
  final FirebaseFirestoreService _firebaseFirestoreService;
  CollectionReference _mediaCollection;

  MediaRepository(
    this._firestore,
    this._firebaseStorageService,
    this._firebaseFirestoreService,
  ) {
    _mediaCollection = _firestore.collection("media");
  }

  @override
  Future<List<Media>> getAvailableMedia() async {
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _mediaCollection.get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    List<Media> mediaList = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      try {
        mediaList.add(await MediaDto.fromFirestore(doc).toDomain(_firebaseStorageService));
      } catch (e) {
        // Handle so that malformed documents in Firestore does not affect app
      }
    }

    return mediaList;
  }
}
