import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/links/entities.dart';
import '../../domain/links/interface.dart';
import '../../services/firebase_firestore_service.dart';

class LinksRepository implements ILinksRepository {
  LinksRepository(this._firestore, this._firebaseFirestoreService);

  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;

  @override
  Future<AppLinks> getLinks() async {
    try {
      final snapshot = await _firestore.collection('links').get();
      if (snapshot.docs.isEmpty) return const AppLinks();
      // Only one document exists in this collection.
      final data = snapshot.docs.first.data();
      return AppLinks(
        giveLink: data['give_link'] as String?,
        privacyPolicyLink: data['privacy_policy_link'] as String?,
        termsOfUseLink: data['terms_of_use_link'] as String?,
        helpEmail: data['help_email'] as String?,
        reportEmail: data['report_email'] as String?,
      );
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }
}
