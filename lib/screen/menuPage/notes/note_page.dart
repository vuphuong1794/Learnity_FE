import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnity/theme/theme.dart';
import '../../../../models/note_setion.dart';
import '../../../api/note_api.dart';
import '../../../models/note.dart';
import '../../../widgets/menuPage/notes/note_card.dart';
import 'note_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';

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
        Get.snackbar(
          "Lỗi",
          "Không thể tải ghi chú. Vui lòng thử lại sau.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final totalNotes = _filteredSections.fold<int>(
      0,
      (sum, s) => sum + s.notes.length,
    );

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        elevation: 0,
        leading: BackButton(
          color: AppIconStyles.iconPrimary(isDarkMode),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Ghi chú',
          style: TextStyle(
            color: AppTextStyles.normalTextColor(isDarkMode),
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        // actions: [IconButton(icon: Icon(Icons.more_vert), onPressed: () {})],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.2),
            height: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Container(color: AppColors.background),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  style: TextStyle(
                    color: AppTextStyles.normalTextColor(isDarkMode),
                  ),
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    hintStyle: TextStyle(
                      color: AppTextStyles.normalTextColor(
                        isDarkMode,
                      ).withOpacity(0.5), // 🎯 đổi màu hint text
                    ),
                    prefixIcon: Icon(Icons.search),
                    // suffixIcon: Icon(Icons.mic_none),
                    prefixIconColor: AppTextStyles.normalTextColor(isDarkMode),
                    suffixIconColor: AppTextStyles.normalTextColor(isDarkMode),
                    filled: true,
                    fillColor: AppBackgroundStyles.buttonBackgroundSecondary(
                      isDarkMode,
                    ),
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
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTextStyles.subTextColor(isDarkMode),
                            ),
                          ),
                        )
                        : (_filteredSections.isEmpty &&
                            _searchController.text.isNotEmpty)
                        ? Center(
                          child: Text(
                            'Không tìm thấy ghi chú nào khớp với tìm kiếm.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTextStyles.subTextColor(isDarkMode),
                            ),
                          ),
                        )
                        : (_filteredSections.isEmpty &&
                            _searchController.text.isEmpty)
                        ? Center(
                          child: Text(
                            'Bạn chưa có ghi chú nào.\nHãy bắt đầu tạo ghi chú mới.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTextStyles.subTextColor(isDarkMode),
                            ),
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
              color: AppBackgroundStyles.secondaryBackground(isDarkMode),
              padding: EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                '$totalNotes ghi chú',
                style: TextStyle(
                  color: AppTextStyles.normalTextColor(isDarkMode),
                  fontSize: 16,
                ),
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
                backgroundColor: AppBackgroundStyles.buttonBackground(
                  isDarkMode,
                ),
                child: Icon(
                  Icons.edit,
                  color: AppIconStyles.iconPrimary(isDarkMode),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
