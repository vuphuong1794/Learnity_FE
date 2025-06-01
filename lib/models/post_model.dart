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
  int shares;
  final String? uid;
  final DateTime createdAt;
  final bool isLiked;
  final String? sharedByUid;



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
    this.sharedByUid
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
      sharedByUid: map['sharedByUid'],
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
  PostModel copyWith({
    String? postId,
    String? username,
    String? avatarUrl,
    bool? isVerified,
    String? postDescription,
    String? content,
    String? imageUrl,
    int? likes,
    int? comments,
    int? shares,
    String? uid,
    String? sharedByUid,
    DateTime? createdAt,
    bool? isLiked,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      postDescription: postDescription ?? this.postDescription,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      uid: uid ?? this.uid,
      sharedByUid: sharedByUid ?? this.sharedByUid,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

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
      sharedByUid: data['sharedByUid'],
      createdAt: (data['createdAt'] as Timestamp?)!.toDate(),
      isLiked: data['isLiked'] ?? false,
    );
  }


}