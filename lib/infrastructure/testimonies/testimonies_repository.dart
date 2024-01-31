import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wpa_app/domain/testimonies/entities.dart';
import 'package:wpa_app/domain/testimonies/exceptions.dart';
import 'package:wpa_app/domain/testimonies/interfaces.dart';

import '../../app/constants.dart';
import '../../domain/authentication/entities.dart';
import '../../app/injection.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import 'testimonies_dto.dart';

class TestimoniesRepository extends ITestimoniesRepository {
  late final FirebaseFirestore _firestore;
  late final FirebaseFirestoreService _firebaseFirestoreService;
  late final FirebaseStorageService _firebaseStorageService;
  late CollectionReference _testimonysCollection;
  DocumentSnapshot? _lastTestimonyDocument;

  TestimoniesRepository(this._firestore, this._firebaseStorageService,
      this._firebaseFirestoreService) {
    _testimonysCollection = _firestore.collection("testimonies");
  }

  @override
  Future<Testimony> createTestimony(
      {required String request, required bool isAnonymous}) async {
    final LocalUser user = getIt<LocalUser>();
    DocumentReference documentReference;
    DocumentSnapshot documentSnapshot;

    try {
      documentReference = await _testimonysCollection.add(
        TestimoniesDto.newRequestFromDomain(request, isAnonymous, user)
            .newRequestToFirestore(),
      );
      documentSnapshot = await documentReference.get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }

    return TestimoniesDto.fromFirestore(documentSnapshot, user.id)
        .toDomain(_firebaseStorageService);
  }

  @override
  Future<void> deleteTestimony({required String id}) async {
    try {
      await _testimonysCollection.doc(id).delete();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<List<Testimony>> getMyTestimonies() async {
    final LocalUser user = getIt<LocalUser>();
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _testimonysCollection
          .where("user_id", isEqualTo: user.id)
          .where("is_archived", isEqualTo: false)
          .orderBy("date", descending: true)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }

    List<Testimony> myTestimonies = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      Testimony testimony = await TestimoniesDto.fromFirestore(doc, user.id)
          .toDomain(_firebaseStorageService);
      myTestimonies.add(testimony);
    }

    return myTestimonies;
  }

  @override
  Future<List<Testimony>> getMyArchivedTestimonies() async {
    final LocalUser user = getIt<LocalUser>();
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _testimonysCollection
          .where("user_id", isEqualTo: user.id)
          .where("is_archived", isEqualTo: true)
          .orderBy("date", descending: true)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }

    List<Testimony> myTestimonies = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      Testimony testimony = await TestimoniesDto.fromFirestore(doc, user.id)
          .toDomain(_firebaseStorageService);
      myTestimonies.add(testimony);
    }

    return myTestimonies;
  }

  @override
  Future<Testimony> closeTestimony({required String id}) async {
    final LocalUser user = getIt<LocalUser>();
    DocumentReference testimonyReference;
    DocumentSnapshot testimonySnapshot;
    try {
      testimonyReference = _testimonysCollection.doc(id);
      await testimonyReference.update({"is_archived": true});
      testimonySnapshot = await testimonyReference.get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
    return TestimoniesDto.fromFirestore(testimonySnapshot, user.id)
        .toDomain(_firebaseStorageService);
  }

  @override
  Future<List<Testimony>> getMoreTestimonies({
    required int limit,
  }) async {
    final LocalUser user = getIt<LocalUser>();
    List<Testimony> testimonys = [];
    QuerySnapshot querySnapshot;

    if (_lastTestimonyDocument == null) {
      throw TestimoniesException(
          code: TestimoniesExceptionCode.NO_STARTING_DOCUMENT,
          message: 'No starting document defined',
          details:
              'No starting document defined. Call [getTestimonies] first.');
    }

    try {
      querySnapshot = await _testimonysCollection
          .where("is_approved", isEqualTo: true)
          .where("is_archived", isEqualTo: false)
          .orderBy("date", descending: true)
          .startAfterDocument(_lastTestimonyDocument!)
          .limit(limit)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }

    if (querySnapshot.docs.length > 0) {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Testimony testimony = await TestimoniesDto.fromFirestore(doc, user.id)
            .toDomain(_firebaseStorageService);
        testimonys.add(testimony);
      }
      _lastTestimonyDocument = querySnapshot.docs.last;
    } else {
      // Reset tracker if no more documents exist
      _lastTestimonyDocument = null;
    }

    return testimonys;
  }

  @override
  Future<List<Testimony>> getTestimonies({
    required int limit,
  }) async {
    final LocalUser user = getIt<LocalUser>();
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _testimonysCollection
          .where("is_approved", isEqualTo: true)
          .where("is_archived", isEqualTo: false)
          .orderBy("date", descending: true)
          .limit(limit)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }

    List<Testimony> testimonys = [];

    if (querySnapshot.docs.length > 0) {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Testimony testimony = await TestimoniesDto.fromFirestore(doc, user.id)
            .toDomain(_firebaseStorageService);
        testimonys.add(testimony);
      }

      /// save last element to be used by [getMoreTestimonies] function
      _lastTestimonyDocument = querySnapshot.docs.last;
    }

    return testimonys;
  }

  @override
  Future<void> praiseTestimony({required String id}) async {
    final LocalUser user = getIt<LocalUser>();
    try {
      // Using transaction to avoid stale data
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference = _testimonysCollection.doc(id);
        DocumentSnapshot documentSnapshot =
            await transaction.get(documentReference);

        // Check if testimony exists
        if (documentSnapshot.data() == null) {
          throw TestimoniesException(
            code: TestimoniesExceptionCode.TESTIMONY_NOT_FOUND,
            message: 'Testimony not found',
          );
        }

        List<dynamic> praisedBy = documentSnapshot["praised_by"];
        praisedBy..add(user.id);

        transaction.update(documentReference, {"praised_by": praisedBy});
      });
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> reportTestimony({required String id}) async {
    final LocalUser user = getIt<LocalUser>();

    try {
      // Using transaction to avoid stale data
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference = _testimonysCollection.doc(id);
        DocumentSnapshot documentSnapshot =
            await transaction.get(documentReference);

        List<dynamic> reportedBy = documentSnapshot["reported_by"] ?? [];

        if (reportedBy.contains(user.id)) {
          throw TestimoniesException(
            code: TestimoniesExceptionCode.ALREADY_REPORTED,
            message: 'You already reported this testimony',
          );
        }

        reportedBy.add(user.id);

        transaction.update(documentReference, {
          "reported_by": reportedBy,
          "is_approved": false,
        });
      });
    } on TestimoniesException catch (_) {
      rethrow;
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<bool> canAddTestimony() async {
    final LocalUser user = getIt<LocalUser>();
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _testimonysCollection
          .where("user_id", isEqualTo: user.id)
          .where("is_approved", isEqualTo: true)
          .orderBy("date", descending: true)
          .get();
    } on Exception catch (e) {
      throw _firebaseFirestoreService.handleException(e);
    }

    if (querySnapshot.docs.length < kTestimoniesPerUserLimit) {
      return true;
    }

    return false;
  }
}

// TODO: handle SocketExcpetion for loss of internet connection
