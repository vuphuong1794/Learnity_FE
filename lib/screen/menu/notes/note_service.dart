import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/note.dart';
import '../../../models/note_setion.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy tất cả các section và các note
  Future<List<NoteSection>> fetchSections(String userId) async {
    if (userId.isEmpty) {
      print('User ID trống');
      return [];
    }
    final sectionsCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('noteSections');
    final sectionsSnapshot = await sectionsCollection.get();
    List<NoteSection> sections = [];
    for (var sectionDoc in sectionsSnapshot.docs) {
      final sectionId = sectionDoc.id;

      final notesSnapshot =
          await sectionsCollection
              .doc(sectionId)
              .collection('notes')
              .orderBy('lastEditedAt', descending: true)
              .get();

      List<Note> notes =
          notesSnapshot.docs
              .map((noteDoc) => Note.fromMap(noteDoc.data(), noteDoc.id))
              .toList();
      sections.add(NoteSection.fromFirestore(sectionDoc, notes));
    }
    return sections;
  }

  // Thêm một NoteSection mới vào Firestore
  Future<void> addNoteSection(String userId, NoteSection section) async {
    if (userId.isEmpty || section.id.isEmpty) {
      print('User ID or Section ID trống');
      return;
    }
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('noteSections')
        .doc(section.id)
        .set(section.toFirestore());
  }

  // Thêm một ghi chú mới vào section
  Future<void> addNote(String userId, String sectionId, Note note) async {
    if (userId.isEmpty || sectionId.isEmpty) {
      print('User ID or Section ID trống');
      return;
    }
    final docRef =
        _firestore
            .collection('users')
            .doc(userId)
            .collection('noteSections')
            .doc(sectionId)
            .collection('notes')
            .doc();
    await docRef.set(note.toMap(docRef.id));
  }

  // Cập nhật một Note hiện có
  Future<void> updateNote(String userId, String sectionId, Note note) async {
    if (userId.isEmpty || sectionId.isEmpty || note.id.isEmpty) {
      print('User ID, Section ID, or Note ID is empty. Cannot update note.');
      return;
    }
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('noteSections')
        .doc(sectionId)
        .collection('notes')
        .doc(note.id)
        .update(note.toMap(note.id));
  }

  // Xóa một Note khỏi một section cụ thể
  Future<void> deleteNote(
    String userId,
    String sectionId,
    String noteId,
  ) async {
    if (userId.isEmpty || sectionId.isEmpty || noteId.isEmpty) {
      print('User ID, Section ID, or Note ID is empty. Cannot delete note.');
      return;
    }
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('noteSections')
        .doc(sectionId)
        .collection('notes')
        .doc(noteId)
        .delete();
    await _checkAndDeleteEmptySection(userId, sectionId);
  }

  // kiểm tra và xóa section nếu nó rỗng
  Future<void> _checkAndDeleteEmptySection(
    String userId,
    String sectionId,
  ) async {
    if (sectionId == 'Tất cả ghi chú') {
      return;
    }

    final notesInOldSection =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('noteSections')
            .doc(sectionId)
            .collection('notes')
            .limit(1)
            .get();

    if (notesInOldSection.docs.isEmpty) {
      // Nếu không còn ghi chú nào trong section  xóa section đó
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('noteSections')
          .doc(sectionId)
          .delete();
      print('Deleted empty section: $sectionId');
    }
  }

  //Lưu
  Future<void> saveNote(String userId, String oldSectionId, Note note) async {
    final String targetSectionId = 'Tất cả ghi chú';
    final sectionRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('noteSections')
        .doc(targetSectionId);
    final sectionDocSnapshot = await sectionRef.get();
    if (!sectionDocSnapshot.exists) {
      // If 'Tất cả ghi chú' section doc doesn't exist, create it.
      await addNoteSection(userId, NoteSection(id: targetSectionId, notes: []));
    }

    if (note.id.isEmpty) {
      await addNote(userId, targetSectionId, note);
    } else {
      if (oldSectionId.isNotEmpty && oldSectionId != targetSectionId) {
        // Delete the note from its old section.
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('noteSections')
            .doc(oldSectionId)
            .collection('notes')
            .doc(note.id)
            .delete();
        await _checkAndDeleteEmptySection(userId, oldSectionId);
      }
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('noteSections')
          .doc(targetSectionId)
          .collection('notes')
          .doc(note.id)
          .set(note.toMap(note.id));
    }
  }
}
