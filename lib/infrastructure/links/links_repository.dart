import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/links/entities.dart';
import '../../domain/links/interface.dart';
import '../common/firestore_data.dart';

class LinksRepository implements ILinksRepository {
  LinksRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<AppLinks> getLinks() async {
    final snapshot = await _firestore.collection('links').get();
    if (snapshot.docs.isEmpty) return const AppLinks();
    // Only one document exists in this collection.
    final data = snapshot.docs.first.data();
    return AppLinks(
      giveLink: data.nullable<String>('give_link'),
      privacyPolicyLink: data.nullable<String>('privacy_policy_link'),
      termsOfUseLink: data.nullable<String>('terms_of_use_link'),
      helpEmail: data.nullable<String>('help_email'),
      reportEmail: data.nullable<String>('report_email'),
    );
  }
}
