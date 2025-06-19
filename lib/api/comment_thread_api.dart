import 'package:cloud_firestore/cloud_firestore.dart';

class CommentService {
  Future<Map<String, List<Map<String, dynamic>>>> fetchCommentsGroupedByPost(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collectionGroup('comments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    final allComments = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['postId'] = doc.reference.parent.parent?.id;
      return data;
    }).toList();

    // B1: Gom tất cả các postId duy nhất
    final Set<String> uniquePostIds = {
      for (var c in allComments)
        if (c['postId'] != null) c['postId']
    };

    // B2: Lấy tất cả bài viết song song
    final postSnapshots = await Future.wait(
      uniquePostIds.map((id) =>
          FirebaseFirestore.instance.collection('posts').doc(id).get()
      ),
    );

    // B3: Gộp dữ liệu bài viết lại thành map postId -> postData
    final Map<String, Map<String, dynamic>> postMap = {};
    for (var snap in postSnapshots) {
      if (snap.exists && snap.data() != null) {
        postMap[snap.id] = {
          ...snap.data()!,
          'postId': snap.id,
        };
      }
    }

    // B4: Gắn post vào từng comment
    final Map<String, List<Map<String, dynamic>>> groupedComments = {};
    for (var comment in allComments) {
      final postId = comment['postId'];
      if (postId == null || !postMap.containsKey(postId)) continue;

      comment['post'] = postMap[postId];
      groupedComments.putIfAbsent(postId, () => []).add(comment);
    }

    return groupedComments;
  }
}
