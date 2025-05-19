import '../../../../models/note.dart';
import '../../../../models/note_setion.dart';

class NoteService {
  Future<List<NoteSection>> fetchSections() async {
    await Future.delayed(Duration(milliseconds: 200));
    return [
      NoteSection(
        id: 'today',
        title: 'Hôm nay',
        notes: [
          Note(id: 'n1', title: '30 ngày học tiếng anh',time: '13h30', subtitle: 'Day 1 Học từ vựng'),
        ],
      ),

      NoteSection(
        id: '2025',
        title: '2025',
        notes: [
          Note(
            id: 'n2',
            title: 'Học Tiếng Anh',
            time: '16/05/25',
            subtitle: 'tôi muốn đạt 8. IELTS trong năm nay',
          ),
          Note(
            id: 'n3',
            title: 'Học Toán',
            time: '13/04/25',
            subtitle: 'tôi muốn học giỏi toán hơn tất cả các bạn…',
          ),
          Note(
            id: 'n4',
            title: 'Học Tiếng Anh',
            time: '11/02/25',
            subtitle: 'tôi muốn đạt 8. IELTS trong năm nay',
          ),
        ],
      ),
      NoteSection(
        id: '2024',
        title: '2024',
        notes: [
          Note(
            id: 'n5',
            title: 'Học Tiếng Anh',
            time: '16/05/24',
            subtitle: 'tôi muốn đạt 8. IELTS trong năm nay',
          ),
          Note(
            id: 'n6',
            title: 'Học Toán',
            time: '13/04/24',
            subtitle: 'tôi muốn học giỏi toán hơn tất cả các bạn…',
          ),
          Note(
            id: 'n7',
            title: 'Học Tiếng Anh',
            time: '11/02/24',
            subtitle: 'tôi muốn đạt 8. IELTS trong năm nay',
          ),
          Note(
            id: 'n8',
            title: 'Học Tiếng Anh',
            time: '11/02/24',
            subtitle: 'tôi muốn đạt 8. IELTS trong năm nay',
          ),
        ],
      ),
      NoteSection(
        id: '2023',
        title: '2024',
        notes: [
          Note(
            id: 'n5',
            title: 'Học Tiếng Anh',
            time: '16/05/24',
            subtitle: 'tôi muốn đạt 8. IELTS trong năm nay',
          ),
          Note(
            id: 'n6',
            title: 'Học Toán',
            time: '13/04/24',
            subtitle: 'tôi muốn học giỏi toán hơn tất cả các bạn…',
          ),
          Note(
            id: 'n7',
            title: 'Học Tiếng Anh',
            time: '11/02/24',
            subtitle: 'tôi muốn đạt 8. IELTS trong năm nay',
          ),
          Note(
            id: 'n8',
            title: 'Học Tiếng Anh',
            time: '11/02/24',
            subtitle: 'tôi muốn đạt 8. IELTS trong năm nay',
          ),
        ],
      ),
    ];
  }
}
