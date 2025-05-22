import 'package:flutter/material.dart';
import '../../../../models/note_setion.dart'; // Adjust path
import '../../../theme/theme.dart'; // Adjust path
import 'package:intl/intl.dart';
import 'NoteDetailPage.dart';
import 'note_service.dart';

class Notecard extends StatelessWidget {
  final NoteSection section;
  final String currentUserUid;
  final VoidCallback? onNoteChanged;

  const Notecard({
    Key? key,
    required this.section,
    required this.currentUserUid,
    this.onNoteChanged,
  }) : super(key: key);

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String noteId,
    NoteService service,
  ) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa ghi chú này không?'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: Text('Xóa'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.buttonText,
                backgroundColor: AppColors.buttonBg
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await service.deleteNote(
          currentUserUid,
          section.id,
          noteId,
        );
        onNoteChanged?.call();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Đã xóa ghi chú.')));
        }
      } catch (e) {
        print('Error deleting note: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa ghi chú: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final NoteService _service = NoteService();
    if (section.notes.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 8),
          ...section.notes.map(
            (note) => Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Colors.white.withOpacity(0.85),
              margin: EdgeInsets.only(bottom: 8),
              elevation: 1.0,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => NoteDetailPage(
                            note: note,
                            sectionId: section.id,
                            currentUserUid: currentUserUid,
                          ),
                    ),
                  );
                  if (result == true) {
                    // true if note was saved/changed
                    onNoteChanged?.call();
                  }
                },
                onLongPress: () {
                  _showDeleteConfirmation(context, note.id, _service);
                },
                child: ListTile(
                  title: Text(
                    note.title.isEmpty ? "(Không có tiêu đề)" : note.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${DateFormat('HH:mm dd/MM/yyyy', 'vi_VN').format(note.lastEditedAt)} | ${note.subtitle}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.black.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
