import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/forum/entities.dart';
import '../common/helpers.dart';

Forum forumFromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
  final data = snapshot.data();
  if (!snapshot.exists || data == null) return const Forum.empty();
  return Forum(
    id: snapshot.id,
    title: data['title'] ?? '',
    isFrozen: data['is_frozen'] ?? false,
    isReadOnly: data['is_read_only'] ?? false,
  );
}

ForumThread threadFromFirestore(
  String forumId,
  String id,
  Map<String, dynamic> data,
) {
  return ForumThread(
    id: id,
    forumId: forumId,
    title: data['title'] ?? '',
    authorId: data['author_id'] ?? '',
    authorName: data['author_name'] ?? '',
    authorImageUrl: data['author_image_url'],
    // Pending server timestamps (local writes) read as null; use "now".
    createdAt: toDateTime(data['created_at']),
    updatedAt: toDateTime(data['updated_at']),
    commentCount: data['comment_count'] ?? 0,
    isFrozen: data['is_frozen'] ?? false,
    isHidden: data['is_hidden'] ?? false,
  );
}

Map<String, dynamic> newThreadDocument(NewThread thread) => {
      'title': thread.title,
      'author_id': thread.authorId,
      'author_name': thread.authorName,
      'author_image_url': thread.authorImageUrl,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'comment_count': 0,
      'is_frozen': false,
      'is_hidden': false,
    };

Comment commentFromFirestore(
  String threadId,
  String id,
  Map<String, dynamic> data,
) {
  return Comment(
    id: id,
    threadId: threadId,
    body: data['body'] ?? '',
    authorId: data['author_id'] ?? '',
    authorName: data['author_name'] ?? '',
    authorImageUrl: data['author_image_url'],
    createdAt: toDateTime(data['created_at']),
    updatedAt: toDateTime(data['updated_at']),
    parentId: data['parent_id'],
    isHidden: data['is_hidden'] ?? false,
    isDeleted: data['is_deleted'] ?? false,
    likedBy: List<String>.from(data['liked_by'] ?? []),
    reportCount: data['report_count'] ?? 0,
  );
}

Map<String, dynamic> newCommentDocument(NewComment comment) => {
      'thread_id': comment.threadId,
      'body': comment.body,
      'author_id': comment.authorId,
      'author_name': comment.authorName,
      'author_image_url': comment.authorImageUrl,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'parent_id': comment.parentId,
      'is_hidden': false,
      'is_deleted': false,
      'liked_by': [],
      'report_count': 0,
    };
