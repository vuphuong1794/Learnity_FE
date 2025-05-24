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
  });

  factory UserInfoModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserInfoModel(
      displayName: map['displayName'],
      username: map['username'],
      avatarUrl: map['avatarUrl'],
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      uid: uid,
      viewPermission: map['view_permission'] as String?,
    );
  }
}

