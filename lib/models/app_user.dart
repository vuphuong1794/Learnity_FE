class AppUser {
  AppUser({
    required this.avatarUrl,
    required this.bio,
    required this.name,
    required this.createdAt,
    required this.isOnline,
    required this.id,
    required this.lastActive,
    required this.email,
  });
  late String avatarUrl;
  late String bio;
  late String name;
  late String createdAt;
  late bool isOnline;
  late String id;
  late String lastActive;
  late String email;

  AppUser.fromJson(Map<String, dynamic> json) {
    avatarUrl = json['avatarUrl'] ?? '';
    bio = json['bio'] ?? '';
    name = json['username'] ?? '';
    createdAt = json['created_at'] ?? '';
    isOnline = json['is_online'] ?? false;
    id = json['uid'] ?? '';
    lastActive = json['last_active'] ?? '';
    email = json['email'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['avatarUrl'] = avatarUrl;
    data['bio'] = bio;
    data['username'] = name;
    data['created_at'] = createdAt;
    data['is_online'] = isOnline;
    data['uid'] = id;
    data['last_active'] = lastActive;
    data['email'] = email;
    return data;
  }
}