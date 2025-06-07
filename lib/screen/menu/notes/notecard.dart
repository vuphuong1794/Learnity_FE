import 'package:flutter/material.dart';
import '../../../../models/note_setion.dart';
import '../../../api/note_api.dart';
import '../../../theme/theme.dart';
import 'package:intl/intl.dart';
import 'NoteDetailPage.dart';


class Notecard extends StatefulWidget {
  final NoteSection section;
  final String currentUserUid;
  final VoidCallback? onNoteChanged;

  const Notecard({
    Key? key,
    required this.section,
    required this.currentUserUid,
    this.onNoteChanged,
  }) : super(key: key);

  @override
  State<Notecard> createState() => _NotecardState();
}

class _NotecardState extends State<Notecard> {
  final NoteAPI API = NoteAPI();
  final Set<String> selectedNoteIds = {};
  bool isSelectionMode = false;

  void _toggleSelection(String noteId) {
    setState(() {
      if (selectedNoteIds.contains(noteId)) {
        selectedNoteIds.remove(noteId);
        if (selectedNoteIds.isEmpty) isSelectionMode = false;
      } else {
        selectedNoteIds.add(noteId);
        isSelectionMode = true;
      }
    });
  }

  Future<void> _deleteSelectedNotes() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Xóa ${selectedNoteIds.length} ghi chú?"),
            content: Text(
              "Bạn có chắc chắn muốn xóa những ghi chú đã chọn không?",
            ),
            actions: [
              TextButton(
                child: Text("Hủy"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text("Xóa"),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.buttonText,
                  backgroundColor: AppColors.buttonBg,
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      for (final noteId in selectedNoteIds) {
        await API.deleteNote(widget.currentUserUid, widget.section.id, noteId);
      }
      selectedNoteIds.clear();
      isSelectionMode = false;
      setState(() {});
      widget.onNoteChanged?.call();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đã xóa ghi chú.")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi xóa: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.section.notes.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.section.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 8),
          if (isSelectionMode && selectedNoteIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _deleteSelectedNotes,
                  icon: Icon(Icons.delete),
                  label: Text("Xóa (${selectedNoteIds.length})"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ),
            ),
          ...widget.section.notes.map(
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
                  if (isSelectionMode) {
                    _toggleSelection(note.id);
                  } else {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => NoteDetailPage(
                              note: note,
                              sectionId: widget.section.id,
                              currentUserUid: widget.currentUserUid,
                            ),
                      ),
                    );
                    if (result == true) {
                      widget.onNoteChanged?.call();
                    }
                  }
                },
                onLongPress: () {
                  _toggleSelection(note.id);
                },
                child: ListTile(
                  leading:
                      isSelectionMode
                          ? Checkbox(
                            value: selectedNoteIds.contains(note.id),
                            onChanged: (checked) {
                              _toggleSelection(note.id);
                            },
                          )
                          : null,
                  title: Text(
                    note.title.isEmpty ? " " : note.title,
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
