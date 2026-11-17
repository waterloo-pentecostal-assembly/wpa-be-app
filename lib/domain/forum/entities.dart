import 'package:equatable/equatable.dart';

class Forum extends Equatable {
  const Forum({
    required this.id,
    required this.title,
    required this.isFrozen,
    required this.isReadOnly,
  });

  const Forum.empty()
      : id = '',
        title = '',
        isFrozen = false,
        isReadOnly = false;

  final String id;
  final String title;
  final bool isFrozen;
  final bool isReadOnly;

  @override
  List<Object?> get props => [id, title, isFrozen, isReadOnly];
}

class ForumThread extends Equatable {
  const ForumThread({
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

  final String id;
  final String forumId;
  final String title;
  final String authorId;
  final String authorName;
  final String? authorImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int commentCount;
  final bool isFrozen;
  final bool isHidden;

  @override
  List<Object?> get props => [
        id,
        forumId,
        title,
        authorId,
        authorName,
        authorImageUrl,
        createdAt,
        updatedAt,
        commentCount,
        isFrozen,
        isHidden,
      ];
}

class Comment extends Equatable {
  const Comment({
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

  final String id;
  final String threadId;
  final String body;
  final String authorId;
  final String authorName;
  final String? authorImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Parent comment id for replies (single level of nesting).
  final String? parentId;
  final bool isHidden;
  final bool isDeleted;
  final List<String> likedBy;
  final int reportCount;

  int get likeCount => likedBy.length;
  bool get isReply => parentId != null;

  @override
  List<Object?> get props => [
        id,
        threadId,
        body,
        authorId,
        authorName,
        authorImageUrl,
        createdAt,
        updatedAt,
        parentId,
        isHidden,
        isDeleted,
        likedBy,
        reportCount,
      ];
}

/// Data needed to create a comment; server fields are filled by the repository.
class NewComment extends Equatable {
  const NewComment({
    required this.threadId,
    required this.body,
    required this.authorId,
    required this.authorName,
    this.authorImageUrl,
    this.parentId,
  });

  final String threadId;
  final String body;
  final String authorId;
  final String authorName;
  final String? authorImageUrl;
  final String? parentId;

  @override
  List<Object?> get props =>
      [threadId, body, authorId, authorName, authorImageUrl, parentId];
}

/// Data needed to create a thread.
class NewThread extends Equatable {
  const NewThread({
    required this.forumId,
    required this.title,
    required this.authorId,
    required this.authorName,
    this.authorImageUrl,
  });

  final String forumId;
  final String title;
  final String authorId;
  final String authorName;
  final String? authorImageUrl;

  @override
  List<Object?> get props =>
      [forumId, title, authorId, authorName, authorImageUrl];
}
