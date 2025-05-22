import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String? postId;
  final String? username;
  final String? avatarUrl;
  final bool isVerified;
  final String? postDescription;
  final String? content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final int shares;
  final String? uid;
  final DateTime createdAt;
  final bool isLiked;


  PostModel({
    this.postId,
    this.username,
    this.avatarUrl,
    this.isVerified = false,
    this.postDescription,
    this.content,
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.uid,
    required this.createdAt,
    this.isLiked = false,

  });

  factory PostModel.mockCurrentUser({
    String? postDescription,
    String? content,
    String? imageUrl,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    return PostModel(
      postId: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      avatarUrl: null,
      postDescription: postDescription,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
  }

  factory PostModel.fromFirestore(Map<String, dynamic> map) {
    return PostModel(
      postId: map['postId'] ?? '',
      username: map['username'] ?? '',
      avatarUrl: map['avatarUrl'],
      isVerified: map['isVerified'] ?? false,
      postDescription: map['postDescription'],
      content: map['content'],
      imageUrl: map['imageUrl'],
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      shares: map['shares'] ?? 0,
      uid: map['uid'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'username': username,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'postDescription': postDescription,
      'content': content,
      'imageUrl': imageUrl,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'uid': uid,
      'createdAt': createdAt,
    };
  }
}