import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../constants.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/authentication/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/prayer_requests/exceptions.dart';
import '../../domain/prayer_requests/interfaces.dart';
import '../../injection.dart';
import '../common/firebase_helpers.dart';
import 'prayer_requests_dto.dart';

class PrayerRequestsRepository extends IPrayerRequestsRepository {
  final FirebaseFirestore _firestore;
  CollectionReference _prayerRequestsCollection;
  DocumentSnapshot _lastPrayerRequestDocument;

  PrayerRequestsRepository(this._firestore) {
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
        message: 'An unknown error occured.',
        details: e,
      );
    }

    return PrayerRequestsDto.fromFirestore(documentSnapshot, user.id).toDomain();
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
        message: 'An unknown error occured.',
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
        message: 'An unknown error occured.',
        details: e,
      );
    }

    List<PrayerRequest> myPrayerRequests = [];
    querySnapshot.docs.forEach((element) {
      myPrayerRequests.add(PrayerRequestsDto.fromFirestore(element, user.id).toDomain());
    });

    return myPrayerRequests;
  }

  @override
  Future<List<PrayerRequest>> getMorePrayerRequests({
    int limit,
    DocumentSnapshot startAtDocument,
  }) async {
    final LocalUser user = await getIt<IAuthenticationFacade>().getSignedInUser();
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
        message: 'An unknown error occured.',
        details: e,
      );
    }

    List<PrayerRequest> prayerRequests = [];

    if (querySnapshot.docs.length > 0) {
      querySnapshot.docs.forEach((element) {
        if (element.data()["user_id"] != user.id) {
          prayerRequests.add(PrayerRequestsDto.fromFirestore(element, user.id).toDomain());
        }
      });
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
        message: 'An unknown error occured.',
        details: e,
      );
    }

    List<PrayerRequest> prayerRequests = [];

    if (querySnapshot.docs.length > 0) {
      querySnapshot.docs.forEach((element) {
        if (element.data()["user_id"] != user.id) {
          prayerRequests.add(PrayerRequestsDto.fromFirestore(element, user.id).toDomain());
        }
      });

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
        message: 'An unknown error occured.',
        details: e,
      );
    }
  }

  @override
  Future<void> reportPrayerRequest({String id}) async {
    try {
      // Using transaction to avoid stale data
      await _firestore.runTransaction((transaction) async {
        DocumentReference documentReference = _prayerRequestsCollection.doc(id);
        DocumentSnapshot documentSnapshot = await transaction.get(documentReference);

        int reports = documentSnapshot.data()["reports"];
        reports = reports == null ? 0 : reports + 1;

        if (reports >= kPrayerRequestsReportsLimit) {
          transaction.update(documentReference, {
            "reports": reports,
            "is_safe": false,
          });
        } else {
          transaction.update(documentReference, {
            "reports": reports,
          });
        }
      });
    } on PlatformException catch (e) {
      handlePlatformException(e);
    } catch (e) {
      throw ApplicationException(
        code: ApplicationExceptionCode.UNKNOWN,
        message: 'An unknown error occured.',
        details: e,
      );
    }
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
        message: 'An unknown error occured.',
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
