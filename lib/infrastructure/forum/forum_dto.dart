import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/forum/entities.dart';
import '../common/firestore_data.dart';

Forum forumFromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
  final data = snapshot.data();
  if (!snapshot.exists || data == null) return const Forum.empty();
  return Forum(
    id: snapshot.id,
    title: data.optional('title', ''),
    isFrozen: data.optional('is_frozen', false),
    isReadOnly: data.optional('is_read_only', false),
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
    title: data.optional('title', ''),
    authorId: data.optional('author_id', ''),
    authorName: data.optional('author_name', ''),
    authorImageUrl: data.nullable<String>('author_image_url'),
    // Pending server timestamps (local writes) read as null; use "now".
    createdAt: data.pendingDate('created_at'),
    updatedAt: data.pendingDate('updated_at'),
    commentCount: data.optionalInt('comment_count'),
    isFrozen: data.optional('is_frozen', false),
    isHidden: data.optional('is_hidden', false),
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
    body: data.optional('body', ''),
    authorId: data.optional('author_id', ''),
    authorName: data.optional('author_name', ''),
    authorImageUrl: data.nullable<String>('author_image_url'),
    createdAt: data.pendingDate('created_at'),
    updatedAt: data.pendingDate('updated_at'),
    parentId: data.nullable<String>('parent_id'),
    isHidden: data.optional('is_hidden', false),
    isDeleted: data.optional('is_deleted', false),
    likedBy: data.stringList('liked_by'),
    reportCount: data.optionalInt('report_count'),
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
