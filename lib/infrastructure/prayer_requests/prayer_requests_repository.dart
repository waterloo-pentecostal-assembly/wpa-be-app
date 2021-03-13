import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/constants.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/prayer_requests/exceptions.dart';
import '../../domain/prayer_requests/interfaces.dart';
import '../../app/injection.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import 'prayer_requests_dto.dart';

class PrayerRequestsRepository extends IPrayerRequestsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFirestoreService _firebaseFirestoreService;
  final FirebaseStorageService _firebaseStorageService;
  CollectionReference _prayerRequestsCollection;
  DocumentSnapshot _lastPrayerRequestDocument;

  PrayerRequestsRepository(this._firestore, this._firebaseStorageService,
      this._firebaseFirestoreService) {
    _prayerRequestsCollection = _firestore.collection("prayer_requests");
  }

  @override
  Future<PrayerRequest> createPrayerRequest(
      {String request, bool isAnonymous}) async {
    final LocalUser user = getIt<LocalUser>();
    DocumentReference documentReference;
    DocumentSnapshot documentSnapshot;

    try {
      documentReference = await _prayerRequestsCollection.add(
        PrayerRequestsDto.newRequestFromDomain(request, isAnonymous, user)
            .newRequestToFirestore(),
      );
      documentSnapshot = await documentReference.get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    return PrayerRequestsDto.fromFirestore(documentSnapshot, user.id)
        .toDomain(_firebaseStorageService);
  }

  @override
  Future<void> deletePrayerRequest({String id}) async {
    try {
      await _prayerRequestsCollection.doc(id).delete();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<List<PrayerRequest>> getMyPrayerRequests() async {
    final LocalUser user = getIt<LocalUser>();
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _prayerRequestsCollection
          .where("user_id", isEqualTo: user.id)
          .where("is_answered", isEqualTo: false)
          .orderBy("date", descending: true)
          .get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    List<PrayerRequest> myPrayerRequests = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      PrayerRequest prayerRequest =
          await PrayerRequestsDto.fromFirestore(doc, user.id)
              .toDomain(_firebaseStorageService);
      myPrayerRequests.add(prayerRequest);
    }

    return myPrayerRequests;
  }

  @override
  Future<List<PrayerRequest>> getMyAnsweredPrayerRequests() async {
    final LocalUser user = getIt<LocalUser>();
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _prayerRequestsCollection
          .where("user_id", isEqualTo: user.id)
          .where("is_answered", isEqualTo: true)
          .orderBy("date", descending: true)
          .get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    List<PrayerRequest> myPrayerRequests = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      PrayerRequest prayerRequest =
          await PrayerRequestsDto.fromFirestore(doc, user.id)
              .toDomain(_firebaseStorageService);
      myPrayerRequests.add(prayerRequest);
    }

    return myPrayerRequests;
  }

  @override
  Future<PrayerRequest> closePrayerRequest({String id}) async {
    final LocalUser user = getIt<LocalUser>();
    DocumentReference prayerRequestReference;
    DocumentSnapshot prayerRequestSnapshot;
    try {
      prayerRequestReference = _prayerRequestsCollection.doc(id);
      await prayerRequestReference.update({"is_answered": true});
      prayerRequestSnapshot = await prayerRequestReference.get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
    return PrayerRequestsDto.fromFirestore(prayerRequestSnapshot, user.id)
        .toDomain(_firebaseStorageService);
  }

  @override
  Future<List<PrayerRequest>> getMorePrayerRequests({
    int limit,
    DocumentSnapshot startAtDocument,
  }) async {
    final LocalUser user = getIt<LocalUser>();
    List<PrayerRequest> prayerRequests = [];
    QuerySnapshot querySnapshot;

    if (_lastPrayerRequestDocument == null) {
      throw PrayerRequestsException(
          code: PrayerRequestsExceptionCode.NO_STARTING_DOCUMENT,
          message: 'No starting document defined',
          details:
              'No starting document defined. Call [getPrayerRequests] first.');
    }

    try {
      querySnapshot = await _prayerRequestsCollection
          .where("is_approved", isEqualTo: true)
          .where("is_answered", isEqualTo: false)
          .orderBy("date", descending: true)
          .startAfterDocument(_lastPrayerRequestDocument)
          .limit(limit)
          .get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    if (querySnapshot.docs.length > 0) {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        PrayerRequest prayerRequest =
            await PrayerRequestsDto.fromFirestore(doc, user.id)
                .toDomain(_firebaseStorageService);
        prayerRequests.add(prayerRequest);
      }
      _lastPrayerRequestDocument = querySnapshot.docs.last;
    } else {
      // Reset tracker if no more documents exist
      _lastPrayerRequestDocument = null;
    }

    return prayerRequests;
  }

  @override
  Future<List<PrayerRequest>> getPrayerRequests({
    int limit,
  }) async {
    final LocalUser user = getIt<LocalUser>();
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _prayerRequestsCollection
          .where("is_approved", isEqualTo: true)
          .where("is_answered", isEqualTo: false)
          .orderBy("date", descending: true)
          .limit(limit)
          .get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    List<PrayerRequest> prayerRequests = [];

    if (querySnapshot.docs.length > 0) {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        PrayerRequest prayerRequest =
            await PrayerRequestsDto.fromFirestore(doc, user.id)
                .toDomain(_firebaseStorageService);
        prayerRequests.add(prayerRequest);
      }

      /// save last element to be used by [getMorePrayerRequests] function
      _lastPrayerRequestDocument = querySnapshot.docs.last;
    }

    return prayerRequests;
  }

  @override
  Future<void> prayForPrayerRequest({String id}) async {
    final LocalUser user = getIt<LocalUser>();
    try {
      // Using transaction to avoid stale data
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference = _prayerRequestsCollection.doc(id);
        DocumentSnapshot documentSnapshot =
            await transaction.get(documentReference);

        // Check if prayer request exists
        if (documentSnapshot.data() == null) {
          throw PrayerRequestsException(
            code: PrayerRequestsExceptionCode.PRAYER_REQUEST_NOT_FOUND,
            message: 'Prayer request not found',
          );
        }

        List<dynamic> prayedBy = documentSnapshot.data()["prayed_by"];

        if (prayedBy == null) {
          prayedBy = [user.id];
        } else {
          prayedBy..add(user.id);
        }

        transaction.update(documentReference, {"prayed_by": prayedBy});
      });
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<void> reportPrayerRequest({String id}) async {
    final LocalUser user = getIt<LocalUser>();

    try {
      // Using transaction to avoid stale data
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference = _prayerRequestsCollection.doc(id);
        DocumentSnapshot documentSnapshot =
            await transaction.get(documentReference);

        List<dynamic> reportedBy = documentSnapshot.data()["reported_by"] ?? [];

        if (reportedBy.contains(user.id)) {
          throw PrayerRequestsException(
            code: PrayerRequestsExceptionCode.ALREADY_REPORTED,
            message: 'You already reported this prayer request',
          );
        }

        reportedBy.add(user.id);

        transaction.update(documentReference, {
          "reported_by": reportedBy,
          "is_approved": false,
        });
      });
    } on PrayerRequestsException catch (_) {
      rethrow;
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }
  }

  @override
  Future<bool> canAddPrayerRequest() async {
    final LocalUser user = getIt<LocalUser>();
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _prayerRequestsCollection
          .where("user_id", isEqualTo: user.id)
          .where("is_approved", isEqualTo: true)
          .orderBy("date", descending: true)
          .get();
    } catch (e) {
      _firebaseFirestoreService.handleException(e);
    }

    if (querySnapshot.docs.length < kPrayerRequestPerUserLimit) {
      return true;
    }

    return false;
  }
}

// TODO: handle SocketExcpetion for loss of internet connection
