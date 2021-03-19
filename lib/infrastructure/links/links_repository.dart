import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wpa_app/domain/links/interface.dart';
import 'package:wpa_app/services/firebase_firestore_service.dart';

class LinksRepository extends ILinksRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;
  CollectionReference collectionReference;

  LinksRepository(this._firestore, this._firebaseFirestoreService) {
    collectionReference = _firestore.collection("links");
  }

  @override
  Future<Map<String, dynamic>> getlinks() async {
    QuerySnapshot snapshot;
    try {
      snapshot = await collectionReference.get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
    return snapshot.docs[0].data();
  }
}
