import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wpa_app/domain/links/interface.dart';
import 'package:wpa_app/services/firebase_firestore_service.dart';

class LinksRepository extends ILinksRepository {
  late final FirebaseFirestore _firestore;
  late final FirebaseFirestoreService _firebaseFirestoreService;
  late CollectionReference collectionReference;

  LinksRepository(this._firestore, this._firebaseFirestoreService) {
    collectionReference = _firestore.collection("links");
  }

  @override
  Future<Map<String, dynamic>> getlinks() async {
    QuerySnapshot snapshot;
    try {
      snapshot = await collectionReference.get();
      var docs = snapshot.docs;
      if (docs.isNotEmpty) {
        // only one document in this collection for storing links
        return (snapshot.docs[0].data() ?? {}) as Map<String, dynamic>;
      }
      return {};
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }
}
