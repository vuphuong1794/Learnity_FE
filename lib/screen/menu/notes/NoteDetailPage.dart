import 'package:flutter/material.dart';
import '../../../../models/note.dart';
import '../../../api/note_api.dart';
import '../../../theme/theme.dart';
import 'package:intl/intl.dart';


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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ghi chú trống không được lưu.')),
        );
        Navigator.pop(context, false);
      }
      return;
    }

    //title rỗng
    if (currentTitle.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tiêu đề ghi chú không được để trống.',
              style: TextStyle(color: Colors.blue),
            ),
          ),
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
      lastEditedAt:
          now,
      // nếu là ghi chú mới (id rỗng) → gán thời gian tạo là now; nếu là ghi chú cũ → giữ nguyên thời gian tạo ban đầu.
      createdAt: widget.note.id.isEmpty ? now : widget.note.createdAt,
    );

    try {
      await API.saveNote(
        widget.currentUserUid,
        widget.sectionId,
        updatedNote,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Lỗi khi lưu ghi chú: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu ghi chú: $e')));
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Lưu',),
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.black),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(
                  context,
                ).pop(false);
              }
            },
          ),
          title: Text(
            widget.note.id.isEmpty ? 'Ghi chú mới' : 'Chỉnh sửa ghi chú',
            style: TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.save, color: AppColors.black),
              onPressed: _saveNoteAndPop,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: AppColors.black.withOpacity(0.2),
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
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
              SizedBox(height: 16), // Adjusted spacing
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
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
                    color: AppColors.black.withOpacity(0.8),
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
