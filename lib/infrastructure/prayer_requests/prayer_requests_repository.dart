import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/prayer_requests/exceptions.dart';
import '../../domain/prayer_requests/interfaces.dart';
import '../../injection.dart';
import '../common/firebase_storage_helper.dart';
import '../common/helpers.dart';
import 'prayer_requests_dto.dart';

class PrayerRequestsRepository extends IPrayerRequestsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorageHelper _firebaseStorageHelper;
  CollectionReference _prayerRequestsCollection;
  DocumentSnapshot _lastPrayerRequestDocument;

  PrayerRequestsRepository(this._firestore, this._firebaseStorageHelper) {
    _prayerRequestsCollection = _firestore.collection("prayer_requests");
  }

  @override
  Future<PrayerRequest> createPrayerRequest({String request, bool isAnonymous}) async {
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    DocumentReference documentReference;
    DocumentSnapshot documentSnapshot;

    try {
      documentReference = await _prayerRequestsCollection.add(
        PrayerRequestsDto.newRequestFromDomain(request, isAnonymous, user).newRequestToFirestore(),
      );
      documentSnapshot = await documentReference.get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }

    return PrayerRequestsDto.fromFirestore(documentSnapshot, user.id).toDomain(_firebaseStorageHelper);
  }

  @override
  Future<void> deletePrayerRequest({String id}) async {
    try {
      await _prayerRequestsCollection.doc(id).delete();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }
  }

  @override
  Future<List<PrayerRequest>> getMyPrayerRequests() async {
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _prayerRequestsCollection
          .where("user_id", isEqualTo: user.id)
          .where("is_safe", isEqualTo: true)
          .orderBy("date", descending: true)
          .get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }

    List<PrayerRequest> myPrayerRequests = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      PrayerRequest prayerRequest = await PrayerRequestsDto.fromFirestore(doc, user.id).toDomain(_firebaseStorageHelper);
      myPrayerRequests.add(prayerRequest);
    }

    return myPrayerRequests;
  }

  @override
  Future<List<PrayerRequest>> getMorePrayerRequests({
    int limit,
    DocumentSnapshot startAtDocument,
  }) async {
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    List<PrayerRequest> prayerRequests = [];
    QuerySnapshot querySnapshot;

    if (_lastPrayerRequestDocument == null) {
      throw PrayerRequestsException(
          code: PrayerRequestsExceptionCode.NO_STARTING_DOCUMENT,
          message: 'No starting document defined',
          details: 'No starting document defined. Call [getPrayerRequests] first.');
    }

    try {
      querySnapshot = await _prayerRequestsCollection
          .where("is_safe", isEqualTo: true)
          .orderBy("date", descending: true)
          .startAfterDocument(_lastPrayerRequestDocument)
          .limit(limit)
          .get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }

    if (querySnapshot.docs.length > 0) {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        PrayerRequest prayerRequest = await PrayerRequestsDto.fromFirestore(doc, user.id).toDomain(_firebaseStorageHelper);
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
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _prayerRequestsCollection
          .where("is_safe", isEqualTo: true)
          .orderBy("date", descending: true)
          .limit(limit)
          .get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }

    List<PrayerRequest> prayerRequests = [];

    if (querySnapshot.docs.length > 0) {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        PrayerRequest prayerRequest = await PrayerRequestsDto.fromFirestore(doc, user.id).toDomain(_firebaseStorageHelper);
        prayerRequests.add(prayerRequest);
      }

      /// save last element to be used by [getMorePrayerRequests] function
      _lastPrayerRequestDocument = querySnapshot.docs.last;
    }

    return prayerRequests;
  }

  @override
  Future<void> prayForPrayerRequest({String id}) async {
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    try {
      // Using transaction to avoid stale data
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference = _prayerRequestsCollection.doc(id);
        DocumentSnapshot documentSnapshot = await transaction.get(documentReference);

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
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }
  }

  @override
  Future<bool> reportPrayerRequest({String id}) async {
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    bool isSafe = false;

    try {
      // Using transaction to avoid stale data
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference = _prayerRequestsCollection.doc(id);
        DocumentSnapshot documentSnapshot = await transaction.get(documentReference);

        List<dynamic> reportedBy = documentSnapshot.data()["reported_by"] ?? [];

        if (reportedBy.contains(user.id)) {
          throw PrayerRequestsException(
            code: PrayerRequestsExceptionCode.ALREADY_REPORTED,
            message: 'You already reported this prayer request',
          );
        }

        reportedBy.add(user.id);
        isSafe = reportedBy.length < kPrayerRequestsReportsLimit;

        transaction.update(documentReference, {
          "reported_by": reportedBy,
          "is_safe": isSafe,
        });
      });
    } on PrayerRequestsException catch (_) {
      rethrow;
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }
    return isSafe;
  }

  @override
  Future<bool> canAddPrayerRequest() async {
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
    QuerySnapshot querySnapshot;

    try {
      querySnapshot = await _prayerRequestsCollection
          .where("user_id", isEqualTo: user.id)
          .where("is_safe", isEqualTo: true)
          .orderBy("date", descending: true)
          .get();
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occurred',
        details: e,
      );
    }

    if (querySnapshot.docs.length < kPrayerRequestPerUserLimit) {
      return true;
    }

    return false;
  }
}

// TODO: handle SocketExcpetion for loss of internet connection