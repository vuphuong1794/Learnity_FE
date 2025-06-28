import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../api/user_apis.dart';
import 'video_call_screen.dart';

class CallingScreen extends StatefulWidget {
  final String callID;
  final String userID;
  final String userName;

  const CallingScreen({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  StreamSubscription<DocumentSnapshot>? _subscription;
  bool _isCallActive = true;

  @override
  void initState() {
    super.initState();
    _listenToCallStatus();

    Future.delayed(const Duration(seconds: 30), () {
      if (_isCallActive) {
        _endCall(reason: 'Không có phản hồi từ người nhận.');
      }
    });
  }

  void _listenToCallStatus() {
    _subscription = FirebaseFirestore.instance
        .collection('video_calls')
        .doc(widget.callID)
        .snapshots()
        .listen((doc) {
          final data = doc.data();
          if (data == null) return;

          final status = data['status'];
          if (status == 'accepted') {
            _subscription?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => VideoCallScreen(
                      callID: widget.callID,
                      userID: widget.userID,
                      userName: widget.userName,
                    ),
              ),
            );
          } else if (status == 'rejected') {
            _endCall(reason: 'Người nhận đã từ chối cuộc gọi.');
          }
        });
  }

  void _endCall({String? reason}) async {
    _isCallActive = false;
    _subscription?.cancel();

    await FirebaseFirestore.instance
        .collection('video_calls')
        .doc(widget.callID)
        .update({'status': 'cancelled'});

    if (mounted) {
      Navigator.pop(context);
      if (reason != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(reason)));
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Đang chờ người nhận...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.call_end, color: Colors.white),
              label: const Text('Hủy cuộc gọi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _endCall,
            ),
          ],
        ),
      ),
    );
  }
}
