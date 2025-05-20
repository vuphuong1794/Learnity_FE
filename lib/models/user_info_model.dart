class UserInfoModel {
  final String? nickname;
  final String? fullName;
  final String? avatarUrl;
  late final List<String>? followers;
  final List<String>? following;
  final String? uid;

  UserInfoModel({
    this.nickname,
    this.fullName,
    this.avatarUrl,
    this.followers,
    this.following,
    this.uid,
  });

  factory UserInfoModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserInfoModel(
      nickname: map['nickname'],
      fullName: map['username'],
      avatarUrl: map['avatarUrl'],
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      uid: uid,
    );
  }
}

