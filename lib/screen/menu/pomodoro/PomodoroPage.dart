import 'dart:async';
import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';

import 'PomodoroSettingsPage.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  final int _workDuration = 25 * 60;
  final int _shortBreakDuration = 5 * 60;
  final int _longBreakDuration = 15 * 60;

  late int _remainingSeconds;
  PomodoroPhase _currentPhase = PomodoroPhase.work;
  int _completedWorkSessions = 0;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isRunning = false;
          _nextPhase();
        });
      }
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _startTimer();
      setState(() => _isRunning = true);
    }
  }

  void _nextPhase() {
    if (_currentPhase == PomodoroPhase.work) {
      _completedWorkSessions++;
      if (_completedWorkSessions < 4) {
        _currentPhase = PomodoroPhase.shortBreak;
        _remainingSeconds = _shortBreakDuration;
      } else {
        _currentPhase = PomodoroPhase.longBreak;
        _remainingSeconds = _longBreakDuration;
      }
    } else {
      if (_currentPhase == PomodoroPhase.longBreak) {
        _completedWorkSessions = 0;
      }
      _currentPhase = PomodoroPhase.work;
      _remainingSeconds = _workDuration;
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _currentPhase = PomodoroPhase.work;
    _completedWorkSessions = 0;
    _remainingSeconds = _workDuration;
    _isRunning = false;
  }

  String get timerText {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes : $seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Thêm ngay dưới các field trong _PomodoroPageState:
  int get _currentPhaseDuration {
    switch (_currentPhase) {
      case PomodoroPhase.shortBreak:
        return _shortBreakDuration;
      case PomodoroPhase.longBreak:
        return _longBreakDuration;
      case PomodoroPhase.work:
      default:
        return _workDuration;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Pomodoro',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PomodoroSettingsPage()),
                );
              },
              icon: const Icon(Icons.settings, color: Colors.black),
            ),
          )
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: Colors.black, height: 1),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: _remainingSeconds / _currentPhaseDuration,
                    strokeWidth: 20,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ),
                Text(
                  timerText,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _completedWorkSessions,
                  (index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(Icons.book_online_outlined, color: AppColors.black),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  color: AppColors.white,
                ),
                label: Text(
                  _isRunning ? 'Tạm dừng' : 'Bắt đầu',
                  style: const TextStyle(color: AppColors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBg,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: () {
                  setState(_resetTimer);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
