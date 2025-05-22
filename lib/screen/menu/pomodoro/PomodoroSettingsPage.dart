import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnity/models/pomodoro_settings.dart'; // Import your model

class PomodoroSettingsPage extends StatefulWidget {
  const PomodoroSettingsPage({super.key});

  @override
  State<PomodoroSettingsPage> createState() => _PomodoroSettingsPageState();
}

class _PomodoroSettingsPageState extends State<PomodoroSettingsPage> {
  Pomodoro _currentSettings = Pomodoro(
    workMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    User? user = _auth.currentUser;
    if (user == null) {
      print('User not logged in. Cannot load settings.');
      return;
    }

    try {
      DocumentSnapshot doc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('pomodoroSettings')
              .doc('default')
              .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _currentSettings = Pomodoro.fromFirestore(
            doc.data()! as Map<String, dynamic>,
          );
        });
        print('Pomodoro settings loaded from Firestore for user ${user.uid}.');
      } else {
        print(
          'No custom settings found in Firestore for user ${user.uid}. Using default values.',
        );
        _saveSettingsToFirestore();
      }
    } catch (e) {
      print('Error loading settings from Firestore: $e');
    }
  }

  Future<void> _saveSettingsToFirestore() async {
    User? user = _auth.currentUser;
    if (user == null) {
      print('User not logged in. Cannot save settings to Firestore.');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pomodoroSettings')
          .doc('default')
          .set(
            _currentSettings
                .toFirestore(),
            SetOptions(merge: true),
          );

      print('Pomodoro settings saved to Firestore for user ${user.uid}.');
    } catch (e) {
      print('Error saving settings to Firestore: $e');
    }
  }

  void _resetToDefault() {
    setState(() {
      _currentSettings = Pomodoro(
        workMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
      );
    });
    _saveSettingsToFirestore();
  }

  void _saveSettingsAndPop() {
    _saveSettingsToFirestore();
    Navigator.pop(context, _currentSettings);
  }

  Future<void> _showMinutePicker({
    required String title,
    required int initialValue,
    required ValueChanged<int> onPicked,
  }) async {
    int temp = initialValue;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => SizedBox(
            height: 300,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: StatefulBuilder(
                    builder: (context, setSheetState) {
                      return ListWheelScrollView.useDelegate(
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.5,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged:
                            (i) => setSheetState(() => temp = i + 1),
                        controller: FixedExtentScrollController(
                          initialItem: initialValue - 1,
                        ),
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            final val = index + 1;
                            return Center(
                              child: Text(
                                val.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight:
                                      val == temp
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      val == temp ? Colors.teal : Colors.grey,
                                ),
                              ),
                            );
                          },
                          childCount: 60,
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    onPicked(temp);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );
  }

  Widget _buildPickerField(
    String label,
    int value,
    ValueChanged<int> onPicked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap:
              () => _showMinutePicker(
                title: label,
                initialValue: value,
                onPicked: (newValue) {
                  setState(() {
                    if (label == 'Làm việc') {
                      _currentSettings = _currentSettings.copyWith(
                        workMinutes: newValue,
                      );
                    } else if (label == 'Nghỉ ngắn') {
                      _currentSettings = _currentSettings.copyWith(
                        shortBreakMinutes: newValue,
                      );
                    } else if (label == 'Nghỉ dài') {
                      _currentSettings = _currentSettings.copyWith(
                        longBreakMinutes: newValue,
                      );
                    }
                  });
                },
              ),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text('phút', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Cài đặt',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed:
              _saveSettingsAndPop,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Colors.black, height: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Độ dài thời gian',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPickerField(
              'Làm việc',
              _currentSettings.workMinutes,
              (v) => setState(
                () =>
                    _currentSettings = _currentSettings.copyWith(
                      workMinutes: v,
                    ),
              ),
            ),
            _buildPickerField(
              'Nghỉ ngắn',
              _currentSettings.shortBreakMinutes,
              (v) => setState(
                () =>
                    _currentSettings = _currentSettings.copyWith(
                      shortBreakMinutes: v,
                    ),
              ),
            ),
            _buildPickerField(
              'Nghỉ dài',
              _currentSettings.longBreakMinutes,
              (v) => setState(
                () =>
                    _currentSettings = _currentSettings.copyWith(
                      longBreakMinutes: v,
                    ),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveSettingsAndPop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _resetToDefault,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Đặt lại',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
