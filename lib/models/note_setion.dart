import 'package:cloud_firestore/cloud_firestore.dart';
import 'note.dart';

class NoteSection {
  final String id;
  final List<Note> notes;

  NoteSection({required this.id, required this.notes});

  // title luôn returns 'Tất cả ghi chú'
  String get title {
    return 'Tất cả ghi chú';
  }
  // Trả về thời điểm chỉnh sửa gần nhất trong danh sách ghi chú
  DateTime get latestEditTime {
    if (notes.isEmpty) {
      return DateTime(1970);
    }
    final sortedNotes = List<Note>.from(notes);
    sortedNotes.sort((a, b) => b.lastEditedAt.compareTo(a.lastEditedAt));
    return sortedNotes.first.lastEditedAt;
  }

  factory NoteSection.fromFirestore(
    DocumentSnapshot doc,
    List<Note> fetchedNotes,
  ) {
    return NoteSection(id: doc.id, notes: fetchedNotes);
  }

  Map<String, dynamic> toFirestore() {
    return {};
  }
  NoteSection copyWith({String? id, List<Note>? notes}) {
    return NoteSection(id: id ?? this.id, notes: notes ?? this.notes);
  }
}
