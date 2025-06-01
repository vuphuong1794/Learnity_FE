import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupPostModel {
  final String postId;
  final String groupId;
  final String authorUid;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String? title;
  final String? text;
  final String? imageUrl;
  final List<String> likedBy;
  final int commentsCount;
  final int sharesCount;
  final DateTime createdAt;
  bool isLikedByCurrentUser;

  GroupPostModel({
    required this.postId,
    required this.groupId,
    required this.authorUid,
    this.authorUsername,
    this.authorAvatarUrl,
    this.title,
    this.text,
    this.imageUrl,
    this.likedBy = const [],
    this.commentsCount = 0,
    this.sharesCount = 0,
    required this.createdAt,
    this.isLikedByCurrentUser = false,
  });

  int get likesCount => likedBy.length;

  factory GroupPostModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentUser = FirebaseAuth.instance.currentUser;
    final List<String> likedByList = List<String>.from(data['likedBy'] ?? []);

    return GroupPostModel(
      postId: doc.id,
      groupId: data['groupId'] ?? '',
      authorUid: data['authorUid'] ?? '',
      authorUsername: data['authorUsername'] as String?,
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
      title: data['title'] as String?,
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      likedBy: likedByList,
      commentsCount: data['commentsCount'] as int? ?? 0,
      sharesCount: data['sharesCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLikedByCurrentUser:
      currentUser != null ? likedByList.contains(currentUser.uid) : false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'authorUid': authorUid,
      'authorUsername': authorUsername,
      'authorAvatarUrl': authorAvatarUrl,
      'title': title,
      'text': text,
      'imageUrl': imageUrl,
      'likedBy': likedBy,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GroupPostModel copyWith({
    String? postId,
    String? groupId,
    String? authorUid,
    String? authorUsername,
    String? authorAvatarUrl,
    String? title,
    String? text,
    String? imageUrl,
    List<String>? likedBy,
    int? commentsCount,
    int? sharesCount,
    DateTime? createdAt,
    bool? isLikedByCurrentUser,
  }) {
    final newLikedBy = likedBy ?? this.likedBy;
    return GroupPostModel(
      postId: postId ?? this.postId,
      groupId: groupId ?? this.groupId,
      authorUid: authorUid ?? this.authorUid,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      title: title ?? this.title,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      likedBy: newLikedBy,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      createdAt: createdAt ?? this.createdAt,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }
}