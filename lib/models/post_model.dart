import 'package:firebase_auth/firebase_auth.dart';

class PostModel {
  final String id;
  final String username;
  final String? userImage;
  final bool isVerified;
  final String? postDescription;
  final String? content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.username,
    this.userImage,
    this.isVerified = false,
    this.postDescription,
    this.content,
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  factory PostModel.mockCurrentUser({
    String? postDescription,
    String? content,
    String? imageUrl,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    return PostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      userImage: null,
      postDescription: postDescription,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      userImage: map['userImage'],
      isVerified: map['isVerified'] ?? false,
      postDescription: map['postDescription'],
      content: map['content'],
      imageUrl: map['imageUrl'],
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      shares: map['shares'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'userImage': userImage,
      'isVerified': isVerified,
      'postDescription': postDescription,
      'content': content,
      'imageUrl': imageUrl,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'isLiked': isLiked,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}