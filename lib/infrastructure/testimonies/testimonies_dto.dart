import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wpa_app/domain/testimonies/entities.dart';
import 'package:wpa_app/domain/user_profile/entities.dart';

import '../../domain/authentication/entities.dart';
import '../../services/firebase_storage_service.dart';
import '../common/helpers.dart';

class TestimoniesDto {
  final String? id;
  final String userId;
  final String request;
  final List<String>? praisedBy;
  final List<String>? reportedBy;
  final bool? hasPraised;
  final bool? hasReported;
  final bool? isMine;
  final bool? isApproved;
  final Timestamp date;
  final bool isAnonymous;
  final UserSnippetDto userSnippet;
  final bool? isAnswered;

  factory TestimoniesDto.newRequestFromDomain(
      String request, bool isAnonymous, LocalUser user) {
    return TestimoniesDto._(
      userId: user.id,
      request: request,
      date: Timestamp.now(),
      isAnonymous: isAnonymous,
      userSnippet: UserSnippetDto.fromDomain(user),
    );
  }

  factory TestimoniesDto.fromFirestore(
      DocumentSnapshot doc, String signedInUserId) {
    var data = (doc.data() ?? {}) as Map<String, dynamic>;
    List<String> _praisedBy = [];
    List<String> _reportedBy = [];
    List<dynamic> _praisedByFirestore = findOrDefaultTo(data, 'praised_by', []);
    List<dynamic> _reportedByFirestore =
        findOrDefaultTo(data, 'reported_by', []);
    String _userId = findOrThrowException(data, 'user_id');

    _praisedByFirestore.forEach((element) {
      _praisedBy.add(element.toString());
    });

    _reportedByFirestore.forEach((element) {
      _reportedBy.add(element.toString());
    });

    return TestimoniesDto._(
        id: doc.id,
        userId: _userId,
        request: findOrThrowException(data, 'request'),
        praisedBy: _praisedBy,
        reportedBy: _reportedBy,
        hasPraised: _praisedBy.contains(signedInUserId),
        hasReported: _reportedBy.contains(signedInUserId),
        isMine: _userId == signedInUserId,
        isApproved: findOrDefaultTo(data, 'is_approved', false),
        date: findOrThrowException(data, 'date'),
        isAnonymous: findOrThrowException(data, 'is_anonymous'),
        userSnippet: UserSnippetDto.fromFirestore(
            findOrThrowException(data, 'user_snippet')),
        isAnswered: findOrDefaultTo(data, 'is_archived', false));
  }

  const TestimoniesDto._({
    this.id,
    required this.userId,
    required this.request,
    this.praisedBy,
    this.reportedBy,
    this.hasPraised,
    this.hasReported,
    this.isMine,
    this.isApproved,
    this.isAnswered,
    required this.date,
    required this.isAnonymous,
    required this.userSnippet,
  });
}

extension TestimoniesDtoX on TestimoniesDto {
  Future<Testimony> toDomain(
      FirebaseStorageService firebaseStorageService) async {
    return Testimony(
      id: this.id!,
      date: this.date,
      isAnonymous: this.isAnonymous,
      praisedBy: this.praisedBy!,
      reportedBy: this.reportedBy!,
      hasPraised: this.hasPraised!,
      hasReported: this.hasReported!,
      isMine: this.isMine!,
      isApproved: this.isApproved!,
      request: this.request,
      userId: this.userId,
      userSnippet: await this.userSnippet.toDomain(firebaseStorageService),
      isAnswered: this.isAnswered!,
    );
  }

  Map<String, dynamic> newRequestToFirestore() {
    return {
      "date": this.date,
      "is_anonymous": this.isAnonymous,
      "is_approved": false,
      "is_archived": false,
      // Testimony is_safe flag initially set as false.
      // A backend process, automated or otherwise would have
      // to set this a true once it is a safe Testimony.
      // We would have to notify the user whether or not the
      // Testimony went live.
      "request": this.request,
      "user_id": this.userId,
      "user_snippet": this.userSnippet.newRequestToFirestore(),
    };
  }
}

class UserSnippetDto {
  final String firstName;
  final String lastName;
  final String? thumbnailUrl;
  final String? thumbnail;

  factory UserSnippetDto.fromDomain(LocalUser user) {
    return UserSnippetDto._(
      firstName: user.firstName,
      lastName: user.lastName,
      thumbnailUrl: user.thumbnailUrl,
      thumbnail: user.thumbnail,
    );
  }

  factory UserSnippetDto.fromFirestore(Map<String, dynamic> userSnippet) {
    return UserSnippetDto._(
      firstName: findOrThrowException(userSnippet, 'first_name'),
      lastName: findOrThrowException(userSnippet, 'last_name'),
      thumbnail: userSnippet['thumbnail'],
    );
  }

  const UserSnippetDto._({
    required this.firstName,
    required this.lastName,
    this.thumbnailUrl,
    this.thumbnail,
  });
}

extension UserSnippetDtoX on UserSnippetDto {
  Future<UserSnippet> toDomain(
      FirebaseStorageService firebaseStorageService) async {
    // Convert GS Location to Download URL
    String? thumbnailUrl =
        await firebaseStorageService.getNullableDownloadUrl(this.thumbnail);
    ;

    return UserSnippet(
      firstName: this.firstName,
      lastName: this.lastName,
      thumbnailUrl: thumbnailUrl,
      thumbnail: this.thumbnail,
    );
  }

  Map<String, dynamic> newRequestToFirestore() {
    return {
      "first_name": this.firstName,
      "last_name": this.lastName,
      "thumbnail": this.thumbnail,
    };
  }
}
