import 'package:flutter/material.dart';

import 'package:learnity/theme/theme.dart';
import '../../../../models/note_setion.dart';
import '../../../models/note.dart';
import '../notes/note_service.dart';
import 'NoteDetailPage.dart';
import 'notecard.dart';
import 'package:intl/intl.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteService _service = NoteService();
  List<NoteSection> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    final data = await _service.fetchSections();
    setState(() {
      _sections = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalNotes = _sections.fold<int>(0, (sum, s) => sum + s.notes.length);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.black),
        title: Text(
          'Ghi chú',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.more_vert), onPressed: () {})],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: AppColors.black, height: 1.0),
        ),
      ),
      body: Stack(
        children: [
          Container(color: AppColors.background),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: Icon(Icons.mic),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          padding: EdgeInsets.only(bottom: 72),
                          itemCount: _sections.length,
                          itemBuilder:
                              (_, i) => Notecard(section: _sections[i]),
                        ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: AppColors.black,
              padding: EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                '$totalNotes ghi chú',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 55,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                final now = DateTime.now();

                final formattedTime = DateFormat('HH:mm dd/MM/yyyy').format(now);
                final newNote = Note(
                  id: '',        // hoặc các thuộc tính cần thiết khác
                  title: '', subtitle: '', time: formattedTime,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteDetailPage(note: newNote),
                  ),
                );
              },
              backgroundColor: AppColors.black,
              child: Icon(Icons.edit, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
