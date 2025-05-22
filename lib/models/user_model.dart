class UserModel {
  final String uid;
  final String username;
  final String avt;
  final String fullname;
  bool isFollowing;

  UserModel({
    required this.uid,
    required this.username,
    required this.avt,
    required this.fullname,
    this.isFollowing = false,
  });
}