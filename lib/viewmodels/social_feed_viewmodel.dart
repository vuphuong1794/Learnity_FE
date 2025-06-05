import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
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

  Future<List<PostModel>> getFollowingPosts(List<String> followingIds) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('uid', whereIn: followingIds)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return PostModel(
        postId: doc.id,
        username: data['username'],
        avatarUrl: data['avatarUrl'],
        isVerified: data['isVerified'] ?? false,
        postDescription: data['postDescription'],
        content: data['content'],
        imageUrl: data['imageUrl'],
        likes: data['likes'] ?? 0,
        comments: data['comments'] ?? 0,
        shares: data['shares'] ?? 0,
        uid: data['uid'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        isLiked: false, // Có thể cập nhật sau nếu cần
        sharedByUid: data['sharedByUid'],
      );
    }).toList();
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
  // Future<void> toggleLikePost(String postId, String userId) async {
  //   final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
  //   final snapshot = await postRef.get();
  //   List likes = snapshot.data()?['likes'] ?? [];
  //
  //   if (likes.contains(userId)) {
  //     likes.remove(userId);
  //   } else {
  //     likes.add(userId);
  //   }
  //
  //   await postRef.update({'likes': likes});
  // }

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
  // Lấy bài viết cá nhân
  Future<List<PostModel>> getUserPosts(String? userId) async {
    if (userId == null || userId.isEmpty) {
      debugPrint('userId rỗng or null');
      return [];
    }
    final _firestore= FirebaseFirestore.instance;
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('uid', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc.data())).toList();
    } catch (e) {
      debugPrint('Lỗi khi tải bài viết của người dùng $userId: $e');
      rethrow;
    }
  }

  // Share a post
  Future<void> sharePost(String postId, int currentShares) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    await postRef.update({
      'shares': currentShares + 1,
    });
  }
}