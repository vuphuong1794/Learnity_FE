import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final DateTime lastEditedAt;

  Note({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.lastEditedAt,
  });

  factory Note.fromMap(Map<String, dynamic> map, String id) {
    return Note(
      id: id,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastEditedAt: (map['lastEditedAt'] as Timestamp).toDate(),
    );
  }

  // Chuyển đổi Note thành Map để lưu vào Firestore
  Map<String, dynamic> toMap(String docId) {
    return {
      'title': title,
      'subtitle': subtitle,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastEditedAt': Timestamp.fromDate(lastEditedAt),
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? subtitle,
    DateTime? createdAt,
    DateTime? lastEditedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      createdAt: createdAt ?? this.createdAt,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
    );
  }
}
