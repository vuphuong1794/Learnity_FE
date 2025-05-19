import 'package:learnity/models/post_model.dart';

class PostService {

  
  Future<List<PostModel>> fetchPosts() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Return mock data
    return [
      PostModel(
        id: '1',
        username: 'pink_everlasting',
        isVerified: true,
        postDescription: 'Biết điều tốn trong người lớn đây là kính lão đắc thọ',
        content: 'Đánh 83 mà nó ra 38 thì đấy là số may max nhọ\nNhưng mà thôi không sao, tiền thì đã mất rồi không việc gì phải nhắn nhó\nNếu mà cảm thấy cuộc sống bế tắc hãy bốc cho mình một bát họ',
        likes: 123,
        comments: 123,
        shares: 123,
        isLiked: true,
        imageUrl: 'assets/MUN01.jpg',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      PostModel(
        id: '2',
        username: 'pink_everlasting',
        content: 'Sách này hay quá',
        imageUrl: 'assets/MUN01.jpg',
        likes: 123,
        comments: 123,
        shares: 123,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      PostModel(
        id: '3',
        username: 'pink_everlasting',
        isVerified: true,
        postDescription: 'hi',
        content: 'So chí',
        likes: 123,
        comments: 123,
        shares: 123,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
  
  Future<bool> toggleLike(String postId) async {
    // Simulate network request
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Success
  }
  
  Future<bool> addComment(String postId, String comment) async {
    // Simulate network request
    await Future.delayed(const Duration(milliseconds: 800));
    return true; // Success
  }
  
  Future<bool> sharePost(String postId) async {
    // Simulate network request
    await Future.delayed(const Duration(milliseconds: 600));
    return true; // Success
  }
}