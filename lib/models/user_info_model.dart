class UserInfoModel {
  final String? nickname;
  final String? fullName;
  final int? followers;
  final String? avatarUrl;

  UserInfoModel({
    this.nickname,
    this.fullName,
    this.followers,
    this.avatarUrl,
  });

  factory UserInfoModel.fromMap(Map<String, dynamic> map) {
    return UserInfoModel(
      nickname: map['nickname'],
      fullName: map['username'],
      avatarUrl: map['avatarUrl'],
    );
  }
}

