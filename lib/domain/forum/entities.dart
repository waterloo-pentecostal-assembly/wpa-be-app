import 'package:cloud_firestore/cloud_firestore.dart';

class Forum {
  final String id;
  final String title;
  final bool isFrozen;
  final bool isReadOnly;

  Forum({
    required this.id,
    required this.title,
    required this.isFrozen,
    required this.isReadOnly,
  });

  factory Forum.empty() {
    return Forum(
      id: '',
      title: '',
      isFrozen: false,
      isReadOnly: false,
    );
  }
}

class ForumThread {
  final String id;
  final String forumId;
  final String title;
  final String authorId;
  final String authorName;
  final String? authorImageUrl;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final int commentCount;
  final bool isFrozen;
  final bool isHidden;

  ForumThread({
    required this.id,
    required this.forumId,
    required this.title,
    required this.authorId,
    required this.authorName,
    this.authorImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.commentCount,
    required this.isFrozen,
    required this.isHidden,
  });
}

class Comment {
  final String id;
  final String threadId;
  final String body;
  final String authorId;
  final String authorName;
  final String? authorImageUrl;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? parentId; // For 1-level nesting
  final bool isHidden;
  final bool isDeleted;
  final List<String> likedBy;
  final int reportCount;

  Comment({
    required this.id,
    required this.threadId,
    required this.body,
    required this.authorId,
    required this.authorName,
    this.authorImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    required this.isHidden,
    required this.isDeleted,
    required this.likedBy,
    required this.reportCount,
  });

  int get likeCount => likedBy.length;
}
