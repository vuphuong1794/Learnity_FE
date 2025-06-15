import 'package:cloud_firestore/cloud_firestore.dart';

class CommentService {
  Future<Map<String, List<Map<String, dynamic>>>> fetchCommentsGroupedByPost(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collectionGroup('comments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    final allComments = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    final Map<String, List<Map<String, dynamic>>> groupedComments = {};
    for (var comment in allComments) {
      final postId = comment['postId'] ?? '__no_post__';
      groupedComments.putIfAbsent(postId, () => []).add(comment);
    }

    return groupedComments;
  }
}