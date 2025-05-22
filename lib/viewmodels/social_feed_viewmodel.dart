import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnity/models/post_model.dart';

class SocialFeedViewModel {
  // Lấy danh sách bài viết từ Firestore (1 lần)
  Future<List<PostModel>> getPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc.data())).toList();
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  // Lấy danh sách bài viết realtime từ Firestore
  Stream<List<PostModel>> getPostsStream() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc.data())).toList());
  }

  // Like or unlike a post
  Future<void> toggleLike(String postId, bool isLiked, int currentLikes) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    await postRef.update({
      'likes': isLiked ? currentLikes - 1 : currentLikes + 1,
    });
  }

  // Add a comment to a post
  Future<void> addComment(String postId, String content, String username, String avatarUrl) async {
    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc();
    await commentRef.set({
      'content': content,
      'username': username,
      'avatarUrl': avatarUrl,
      'createdAt': DateTime.now(),
    });
    // Tăng số lượng comments
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'comments': FieldValue.increment(1),
    });
  }

  // Share a post
  Future<void> sharePost(String postId, int currentShares) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    await postRef.update({
      'shares': currentShares + 1,
    });
  }
}