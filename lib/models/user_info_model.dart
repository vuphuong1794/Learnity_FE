import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoModel {
  final String? uid;
  final String? displayName;
  final String? username;
  late final List<String>? followers;
  final List<String>? following;
  final String? avatarUrl;
  final String? email;
  final String? bio;
  final String? viewPermission;
  final String? viewSharedPostPermission;
  final String? role;

  UserInfoModel({
    this.uid,
    this.displayName,
    this.username,
    this.followers,
    this.following,
    this.avatarUrl,
    this.email,
    this.bio,
    this.viewPermission,
    this.viewSharedPostPermission,
    this.role,
  });

  factory UserInfoModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserInfoModel(
      displayName: map['displayName'],
      username: map['username'],
      avatarUrl: map['avatarUrl'],
      email: map['email'],
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      uid: uid,
      viewPermission: map['view_permission'] as String?,
      viewSharedPostPermission: map['view_shared_post_permission'] as String?,
      role: map['role'] ?? 'user',
    );
  }

  factory UserInfoModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserInfoModel(
      uid: doc.id,
      displayName: data['displayName'],
      username: data['username'],
      avatarUrl: data['avatarUrl'],
      email: data['email'],
      bio: data['bio'],
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      role: data['role'] ?? 'user',
    );
  }

}

