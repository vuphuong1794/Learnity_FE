import 'package:flutter/material.dart';
import '../../../../models/note_setion.dart';
import '../../../api/note_api.dart';
import 'package:intl/intl.dart';
import 'note_detail_page.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

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

  Future<void> _deleteSelectedNotes(bool isDarkMode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
            title: Text("Xóa ${selectedNoteIds.length} ghi chú?", style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
            content: Text(
              "Bạn có chắc chắn muốn xóa những ghi chú đã chọn không?", style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode)),
            ),
            actions: [
              TextButton(
                child: Text("Hủy", style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode))),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text("Xóa"),
                style: TextButton.styleFrom(
                  foregroundColor: AppTextStyles.buttonTextColor(isDarkMode),
                  backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
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
              color: AppTextStyles.normalTextColor(isDarkMode),
            ),
          ),
          SizedBox(height: 8),
          if (isSelectionMode && selectedNoteIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _deleteSelectedNotes(isDarkMode);
                  },
                  icon: Icon(Icons.delete, color: AppIconStyles.iconPrimary(isDarkMode)),
                  label: Text("Xóa (${selectedNoteIds.length})", style: TextStyle(color: AppTextStyles.buttonTextColor(isDarkMode))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                  ),
                ),
              ),
            ),
          ...widget.section.notes.map(
            (note) => Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: AppBackgroundStyles.secondaryBackground(isDarkMode),
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
                            fillColor: MaterialStateProperty.all(AppBackgroundStyles.buttonBackgroundSecondary(isDarkMode)),      // Nền đỏ
                            checkColor: AppTextStyles.buttonTextColor(isDarkMode),  
                          )
                          : null,
                  title: Text(
                    note.title.isEmpty ? " " : note.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTextStyles.normalTextColor(isDarkMode),
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
                      color: AppTextStyles.subTextColor(isDarkMode),
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
