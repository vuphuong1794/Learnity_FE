import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../models/note.dart';
import '../../../api/note_api.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

class NoteDetailPage extends StatefulWidget {
  final Note note;
  final String sectionId;
  final String currentUserUid;

  const NoteDetailPage({
    Key? key,
    required this.note,
    required this.sectionId,
    required this.currentUserUid,
  }) : super(key: key);

  @override
  _NoteDetailPageState createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  final NoteAPI API = NoteAPI();
  late DateTime _lastEditedAtDisplay;

  bool _hasContentChanged = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _subtitleController = TextEditingController(text: widget.note.subtitle);
    _lastEditedAtDisplay = widget.note.lastEditedAt;
    _titleController.addListener(_onContentChanged);
    _subtitleController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    // kiểm tra thay đổi
    final bool changed =
        _titleController.text != widget.note.title ||
        _subtitleController.text != widget.note.subtitle;
    if (changed != _hasContentChanged) {
      setState(() {
        _hasContentChanged = changed;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onContentChanged);
    _subtitleController.removeListener(_onContentChanged);
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _saveNoteAndPop() async {
    final String currentTitle = _titleController.text.trim();
    final String currentSubtitle = _subtitleController.text.trim();

    // cả title và sub đều rỗng
    if (widget.note.id.isEmpty &&
        currentTitle.isEmpty &&
        currentSubtitle.isEmpty) {
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Ghi chú mới không thể lưu khi cả tiêu đề và nội dung đều trống.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        Navigator.pop(context, false);
      }
      return;
    }

    //title rỗng
    if (currentTitle.isEmpty) {
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Tiêu đề ghi chú không được để trống.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
      return;
    }

    // nội dung không thay đổi so với ghi chú gốc, không lưu.
    if (!_hasContentChanged && widget.note.id.isNotEmpty) {
      Navigator.pop(context, false);
      return;
    }

    final DateTime now = DateTime.now();
    final Note updatedNote = widget.note.copyWith(
      title: currentTitle,
      subtitle: currentSubtitle,
      lastEditedAt: now,
      // nếu là ghi chú mới (id rỗng) → gán thời gian tạo là now; nếu là ghi chú cũ → giữ nguyên thời gian tạo ban đầu.
      createdAt: widget.note.id.isEmpty ? now : widget.note.createdAt,
    );

    try {
      await API.saveNote(widget.currentUserUid, widget.sectionId, updatedNote);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Lỗi khi lưu ghi chú: $e');
      if (mounted) {
        Get.snackbar(
          "Lỗi",
          "Không thể lưu ghi chú. Vui lòng thử lại.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasContentChanged) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Có thay đổi chưa lưu'),
              content: const Text(
                'Bạn có muốn lưu các thay đổi vào ghi chú này không?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Không lưu'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.buttonText,
                    foregroundColor: AppColors.buttonBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Lưu'),
                ),
              ],
            ),
      );
      if (shouldSave == true) {
        await _saveNoteAndPop();
        return false;
      } else if (shouldSave == false) {
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    //update time
    String displayedTime = DateFormat(
      'HH:mm dd/MM/yyyy',
      'vi_VN',
    ).format(widget.note.lastEditedAt);
    if (widget.note.id.isEmpty) {
      displayedTime = DateFormat(
        'HH:mm dd/MM/yyyy',
        'vi_VN',
      ).format(DateTime.now());
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
        appBar: AppBar(
          backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppIconStyles.iconPrimary(isDarkMode),
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop(false);
              }
            },
          ),
          title: Text(
            widget.note.id.isEmpty ? 'Ghi chú mới' : 'Chỉnh sửa ghi chú',
            style: TextStyle(
              color: AppTextStyles.normalTextColor(isDarkMode),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                Icons.save,
                color: AppIconStyles.iconPrimary(isDarkMode),
              ),
              onPressed: _saveNoteAndPop,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.2),
              height: 1.0,
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  displayedTime,
                  style: TextStyle(
                    color: AppTextStyles.subTextColor(isDarkMode),
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(height: 16), // Adjusted spacing
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTextStyles.normalTextColor(isDarkMode),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Tiêu đề',
                  hintStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _subtitleController,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTextStyles.normalTextColor(
                      isDarkMode,
                    ).withOpacity(0.8),
                  ),
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Nội dung ghi chú...',
                    hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
