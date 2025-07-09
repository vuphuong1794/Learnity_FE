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

class _CallingScreenState extends State<CallingScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<DocumentSnapshot>? _subscription;
  bool _isCallActive = true;
  String _receiverName = "";
  String? _receiverAvatarUrl;
  final _userApi = APIs();
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  Future<void> _fetchReceiverInfo(String receiverId) async {
    final data = await _userApi.getUserInfoById(receiverId);
    if (data != null && mounted) {
      setState(() {
        _receiverName = data['username'] ?? 'Người nhận';
        _receiverAvatarUrl = data['avatarUrl'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Logic cũ
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

          final receiverId = data['receiverId'];
          if (receiverId != null && _receiverName.isEmpty) {
            _fetchReceiverInfo(receiverId);
          }
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
    if (!_isCallActive) return;
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
    _animationController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: _animation,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundImage:
                          (_receiverAvatarUrl != null &&
                                  _receiverAvatarUrl!.isNotEmpty)
                              ? NetworkImage(_receiverAvatarUrl!)
                              : null,
                      child:
                          (_receiverAvatarUrl == null ||
                                  _receiverAvatarUrl!.isEmpty)
                              ? const Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.white70,
                              )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _receiverName.isNotEmpty ? _receiverName : 'Đang tìm kiếm...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đang gọi...',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const Spacer(flex: 3),
                InkWell(
                  onTap: () => _endCall(reason: 'Cuộc gọi đã được hủy.'),
                  borderRadius: BorderRadius.circular(40),
                  child: const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.call_end, color: Colors.white, size: 30),
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
