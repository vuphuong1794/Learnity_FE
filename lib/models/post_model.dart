import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String? postId;
  final String? username;
  final String? avatarUrl;
  final bool isVerified;
  late final String? postDescription;
  late final String? content;
  final List<String>? imageUrls;
  final List<String>? tagList;
  final int likes;
  final int comments;
  int shares;
  final String? uid;
  final DateTime? createdAt;
  final bool isLiked;
  final String? sharedByUid;
  final bool? isHidden;


  PostModel({
    this.postId,
    this.username,
    this.avatarUrl,
    this.isVerified = false,
    this.postDescription,
    this.content,
    this.imageUrls,
    this.tagList,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.uid,
    this.createdAt,
    this.isLiked = false,
    this.sharedByUid,
    this.isHidden,
  });

  factory PostModel.mockCurrentUser({
    String? postDescription,
    String? content,
    List<String>? imageUrls,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    return PostModel(
      postId: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      avatarUrl: null,
      postDescription: postDescription,
      content: content,
      imageUrls: imageUrls,
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
      imageUrls: (map['imageUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      tagList: (map['tagList'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      shares: map['shares'] ?? 0,
      uid: map['uid'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      sharedByUid: map['sharedByUid'],
      isHidden: map['isHidden'] ?? false,
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
      'imageUrls': imageUrls,
      'tagList': tagList,
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
    List<String>? imageUrls,
    List<String>? tagList,
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
      imageUrls: imageUrls ?? this.imageUrls,
      tagList: tagList ?? this.tagList,
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
      imageUrls: (data['imageUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      tagList: (data['tagList'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      shares: data['shares'] ?? 0,
      uid: data['uid'],
      sharedByUid: data['sharedByUid'],
      createdAt: (data['createdAt'] as Timestamp?)!.toDate(),
      isLiked: data['isLiked'] ?? false,
      isHidden: data['isHidden'] ?? false,
    );
  }
  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      postId: map['postId'],
      username: map['username'],
      avatarUrl: map['avatarUrl'],
      isVerified: map['isVerified'] ?? false,
      postDescription: map['postDescription'],
      content: map['content'],
      imageUrls: (map['imageUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      tagList: (map['tagList'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      shares: map['shares'] ?? 0,
      uid: map['uid'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      sharedByUid: map['sharedByUid'],
      isLiked: map['isLiked'] ?? false,
      isHidden: map['isHidden'] ?? false,
    );
  }

}