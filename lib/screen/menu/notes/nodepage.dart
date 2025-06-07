import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';
import '../../../../models/note_setion.dart';
import '../../../api/note_api.dart';
import '../../../models/note.dart';
import 'NoteDetailPage.dart';
import 'notecard.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteAPI API = NoteAPI();
  List<NoteSection> _sections = [];
  List<NoteSection> _filteredSections = [];
  bool _isLoading = true;
  String? _currentUserUid;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        if (_currentUserUid != user.uid) {
          setState(() {
            _currentUserUid = user.uid;
          });
          _loadSections();
        } else if (_currentUserUid == user.uid &&
            _sections.isEmpty &&
            !_isLoading) {
          _loadSections();
        }
      } else {
        setState(() {
          _currentUserUid = null;
          _sections = [];
          _filteredSections = [];
          _isLoading = false;
        });
      }
    });

    if (FirebaseAuth.instance.currentUser != null) {
      _currentUserUid = FirebaseAuth.instance.currentUser!.uid;
      _loadSections();
    } else {
      setState(() {
        _isLoading = false;
      });
    }

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterSections(_searchController.text);
  }

  // Hàm lọc
  void _filterSections(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSections = List.from(_sections);
      });
      return;
    }
    final lowerCaseQuery = query.toLowerCase();
    List<NoteSection> tempFilteredSections = [];

    for (var section in _sections) {
      List<Note> matchedNotes = [];
      for (var note in section.notes) {
        if (note.title.toLowerCase().contains(lowerCaseQuery) ||
            note.subtitle.toLowerCase().contains(lowerCaseQuery)) {
          matchedNotes.add(note);
        }
      }
      if (matchedNotes.isNotEmpty) {
        tempFilteredSections.add(section.copyWith(notes: matchedNotes));
      }
    }

    setState(() {
      _filteredSections = tempFilteredSections;
    });
  }

  // Lấy danh sách section từ Firestore thông qua NoteAPI
  Future<void> _loadSections() async {
    if (_currentUserUid == null) {
      setState(() {
        _isLoading = false;
        _sections = [];
        _filteredSections = [];
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await API.fetchSections(_currentUserUid!);
      setState(() {
        _sections = data;
        _filteredSections = List.from(_sections);
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load sections: $e');
      setState(() {
        _isLoading = false;
        _sections = [];
        _filteredSections = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải ghi chú: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalNotes = _filteredSections.fold<int>(
      0,
      (sum, s) => sum + s.notes.length,
    );

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(
          color: AppColors.black,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
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
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: Icon(Icons.mic_none),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.6),
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
                        : (_currentUserUid == null)
                        ? Center(
                          child: Text(
                            'Vui lòng đăng nhập để xem ghi chú của bạn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                        : (_filteredSections.isEmpty &&
                            _searchController.text.isNotEmpty)
                        ? Center(
                          child: Text(
                            'Không tìm thấy ghi chú nào khớp với tìm kiếm.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                        : (_filteredSections.isEmpty &&
                            _searchController.text.isEmpty)
                        ? Center(
                          child: Text(
                            'Bạn chưa có ghi chú nào.\nNhấn nút "+" để tạo ghi chú mới.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                        : ListView.builder(
                          padding: EdgeInsets.only(bottom: 72),
                          itemCount: _filteredSections.length,
                          itemBuilder:
                              (_, i) => Notecard(
                                section: _filteredSections[i],
                                currentUserUid: _currentUserUid!,
                                onNoteChanged:
                                    _loadSections, // Callback to reload sections
                              ),
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
          if (_currentUserUid != null)
            Positioned(
              bottom: 55,
              right: 16,
              child: FloatingActionButton(
                onPressed: () async {
                  String targetSectionId = 'Tất cả ghi chú';

                  // Ensure the 'Tất cả ghi chú' section exists
                  bool sectionExists = _sections.any(
                    (s) => s.id == targetSectionId,
                  );
                  if (!sectionExists) {
                    await API.addNoteSection(
                      _currentUserUid!,
                      NoteSection(id: targetSectionId, notes: []),
                    );
                  }

                  final now = DateTime.now();
                  final newNote = Note(
                    id: '',
                    title: '',
                    subtitle: '',
                    createdAt: now,
                    lastEditedAt: now,
                  );

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => NoteDetailPage(
                            note: newNote,
                            sectionId: targetSectionId,
                            currentUserUid: _currentUserUid!,
                          ),
                    ),
                  );

                  if (result == true) {
                    _loadSections(); // Reload sections to reflect changes
                  }
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
