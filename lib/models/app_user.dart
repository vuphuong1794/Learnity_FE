import 'package:cloud_firestore/cloud_firestore.dart';

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
    required this.role,
  });
  late String avatarUrl;
  late String bio;
  late String name;
  late DateTime createdAt;
  late bool isOnline;
  late String id;
  late DateTime lastActive;
  late String email;
  late String role;

  AppUser.fromJson(Map<String, dynamic> json) {
    avatarUrl = json['avatarUrl'] ?? '';
    bio = json['bio'] ?? '';
    name = json['username'] ?? '';
    
    var created = json['createdAt'];
    createdAt = (created is Timestamp) ? created.toDate() : DateTime.tryParse(created?.toString() ?? '') ?? DateTime.now();

    isOnline = json['is_online'] ?? false;
    id = json['uid'] ?? '';

    var last = json['last_active'];
    lastActive = (last is Timestamp) ? last.toDate() : DateTime.tryParse(last?.toString() ?? '') ?? DateTime.now();

    email = json['email'] ?? '';
    role = json['role'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['avatarUrl'] = avatarUrl;
    data['bio'] = bio;
    data['username'] = name;
    data['createdAt'] = Timestamp.fromDate(createdAt);
    data['is_online'] = isOnline;
    data['uid'] = id;
    data['last_active'] = Timestamp.fromDate(lastActive);
    data['email'] = email;
    data['role'] = role;
    return data;
  }
}