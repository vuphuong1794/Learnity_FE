import 'package:cloud_firestore/cloud_firestore.dart';

class Pomodoro {
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final DateTime? lastUpdated;

  Pomodoro({
    required this.workMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    this.lastUpdated,
  });

  factory Pomodoro.fromFirestore(Map<String, dynamic> data) {
    return Pomodoro(
      workMinutes: data['workMinutes'] as int? ?? 25,
      shortBreakMinutes: data['shortBreakMinutes'] as int? ?? 5,
      longBreakMinutes: data['longBreakMinutes'] as int? ?? 15,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workMinutes': workMinutes,
      'shortBreakMinutes': shortBreakMinutes,
      'longBreakMinutes': longBreakMinutes,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  Pomodoro copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    DateTime? lastUpdated,
  }) {
    return Pomodoro(
      workMinutes: workMinutes ?? this.workMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
