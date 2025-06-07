import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnity/models/pomodoro_settings.dart';

class PomodoroApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>>? _getSettingsDocRef() {
    final user = _currentUser;
    if (user == null) {
      print('Lỗi: Người dùng chưa đăng nhập.');
      return null;
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pomodoroSettings')
        .doc('default');
  }

  Future<Pomodoro?> loadSettings() async {
    final docRef = _getSettingsDocRef();
    if (docRef == null) return null;

    try {
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        print('Cài đặt đã được tải từ Firestore.');
        return Pomodoro.fromFirestore(doc.data()!);
      } else {
        print('Không tìm thấy cài đặt tùy chỉnh. Sẽ tạo cài đặt mặc định.');
        return Pomodoro(
          workMinutes: 25,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
        );
      }
    } catch (e) {
      print('Lỗi khi tải cài đặt từ Firestore: $e');
      return null;
    }
  }

  Future<void> saveSettings(Pomodoro settings) async {
    final docRef = _getSettingsDocRef();
    if (docRef == null) return;

    try {
      await docRef.set(settings.toFirestore(), SetOptions(merge: true));
      print('Cài đặt đã được lưu vào Firestore.');
    } catch (e) {
      print('Lỗi khi lưu cài đặt vào Firestore: $e');
    }
  }
}
