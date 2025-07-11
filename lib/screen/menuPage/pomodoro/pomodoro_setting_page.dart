import 'package:flutter/material.dart';
import 'package:learnity/models/pomodoro_settings.dart';

import '../../../api/pomodoro_api.dart';

import 'package:provider/provider.dart';
import 'package:learnity/theme/theme.dart';
import 'package:learnity/theme/theme_provider.dart';

import '../../../widgets/common/confirm_modal.dart';

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

  Pomodoro? _initialSettings;
  final PomodoroApi _pomodoroApi = PomodoroApi();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final settings = await _pomodoroApi.loadSettings();
    if (settings != null) {
      setState(() {
        _currentSettings = settings;
        _initialSettings = settings.copyWith();
      });
    } else {
      _initialSettings = _currentSettings.copyWith();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettingsToFirestore() async {
    await _pomodoroApi.saveSettings(_currentSettings);
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

  Future<void> _showExitConfirmDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    final bool? didConfirm = await showConfirmModal(
      context: context,
      isDarkMode: isDarkMode,
      title: 'Lưu thay đổi?',
      content: 'Bạn có muốn lưu các thay đổi trước khi thoát?',
      cancelText: 'Thoát không lưu',
      confirmText: 'Lưu & Thoát',
    );

    if (!mounted) return; // Kiểm tra nếu widget còn tồn tại

    if (didConfirm == true) {
      _saveSettingsAndPop();
    } else if (didConfirm == false) {
      Navigator.pop(context, _initialSettings);
    }
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
    bool isDarkMode,
    String label,
    int value,
    ValueChanged<int> onPicked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTextStyles.normalTextColor(isDarkMode),
          ),
        ),
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
                  color: AppBackgroundStyles.buttonBackground(isDarkMode),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTextStyles.normalTextColor(isDarkMode),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppBackgroundStyles.buttonBackground(isDarkMode),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'phút',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTextStyles.normalTextColor(isDarkMode),
                  ),
                ),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        elevation: 1,
        centerTitle: true,
        title: Text(
          'Cài đặt',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTextStyles.normalTextColor(isDarkMode),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppIconStyles.iconPrimary(isDarkMode),
          ),
          onPressed: _showExitConfirmDialog,
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            color: AppTextStyles.normalTextColor(isDarkMode).withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Độ dài thời gian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTextStyles.normalTextColor(isDarkMode),
              ),
            ),
            const SizedBox(height: 16),
            _buildPickerField(
              isDarkMode,
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
              isDarkMode,
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
              isDarkMode,
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
                    backgroundColor: AppBackgroundStyles.buttonBackground(
                      isDarkMode,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Lưu',
                    style: TextStyle(
                      color: AppTextStyles.buttonTextColor(isDarkMode),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _resetToDefault,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppBackgroundStyles.buttonBackground(
                      isDarkMode,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Đặt lại',
                    style: TextStyle(
                      color: AppTextStyles.buttonTextColor(isDarkMode),
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
