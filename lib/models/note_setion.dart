import 'note.dart';

class NoteSection {
  final String id;
  final String title;
  final List<Note> notes;

  NoteSection({
    required this.id,
    required this.title,
    required this.notes,
  });

  factory NoteSection.fromJson(Map<String, dynamic> json) => NoteSection(
    id: json['id'] as String,
    title: json['title'] as String,
    notes: (json['notes'] as List)
        .map((e) => Note.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notes': notes.map((n) => n.toJson()).toList(),
  };
}
