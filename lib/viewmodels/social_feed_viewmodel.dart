import 'package:learnity/models/post_model.dart';
import 'package:learnity/services/post_service.dart';

class SocialFeedViewModel {
  final PostService _postService = PostService();
  
  // Fetch posts for the feed
  Future<List<PostModel>> getPosts() async {
    try {
      return await _postService.fetchPosts();
    } catch (e) {
      // Log error and return empty list if fetch fails
      print('Error fetching posts: $e');
      return [];
    }
  }

  // Like or unlike a post
  Future<bool> toggleLike(String postId) async {
    try {
      return await _postService.toggleLike(postId);
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Add a comment to a post
  Future<bool> addComment(String postId, String comment) async {
    try {
      return await _postService.addComment(postId, comment);
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Share a post
  Future<bool> sharePost(String postId) async {
    try {
      return await _postService.sharePost(postId);
    } catch (e) {
      print('Error sharing post: $e');
      return false;
    }
  }
}