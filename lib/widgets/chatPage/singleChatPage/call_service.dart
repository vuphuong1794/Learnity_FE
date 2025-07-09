import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:learnity/theme/theme.dart';

import '../../../main.dart';
import 'video_call_screen.dart';
import '../../../api/user_apis.dart';

class CallService {
  static bool _isDialogShowing = false;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static void listen() {
    FirebaseFirestore.instance
        .collection('video_calls')
        .where('receiverId', isEqualTo: APIs.user.uid)
        .snapshots()
        .listen((snapshot) async {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final callID = data['callID'];
            final callerId = data['callerId'];
            final status = data['status'];

            if (status == 'calling') {
              final userInfo = await APIs().getUserInfoById(callerId);
              final callerName = userInfo?['username'] ?? '';
              final avatarUrl = userInfo?['avatarUrl'] ?? '';
              _showIncomingCallDialog(callID, callerName, avatarUrl);
            } else if (status == 'cancelled' || status == 'rejected') {
              _stopRingtone();
              _closeDialogIfOpen();
            }
          }
        });
  }

  static void _showIncomingCallDialog(
    String callID,
    String callerName,
    String? avatarUrl,
  ) {
    if (_isDialogShowing || navigatorKey.currentContext == null) return;
    _isDialogShowing = true;
    _playRingtone();

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cuộc gọi đến',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                  child:
                      (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white70,
                          )
                          : null,
                ),
                const SizedBox(height: 16),
                Text(
                  callerName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCallButton(
                      icon: Icons.call_end,
                      label: 'Từ chối',
                      color: Colors.red,
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('video_calls')
                            .doc(callID)
                            .update({'status': 'rejected'});
                        _stopRingtone();
                        _closeDialogIfOpen();
                      },
                    ),
                    _buildCallButton(
                      icon: Icons.call,
                      label: 'Trả lời',
                      color: Colors.green,
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('video_calls')
                            .doc(callID)
                            .update({'status': 'accepted'});
                        _stopRingtone();
                        _closeDialogIfOpen();

                        Navigator.push(
                          navigatorKey.currentContext!,
                          MaterialPageRoute(
                            builder:
                                (_) => VideoCallScreen(
                                  callID: callID,
                                  userID: APIs.user.uid,
                                  userName: APIs.me.name,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(35),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 14)),
      ],
    );
  }

  static void _playRingtone() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('audio/incoming_call.mp3'), volume: 1);
  }

  static void _stopRingtone() async {
    await _audioPlayer.stop();
  }

  static void _closeDialogIfOpen() {
    if (_isDialogShowing && navigatorKey.currentContext != null) {
      Navigator.of(navigatorKey.currentContext!, rootNavigator: true).pop();
    }
    _isDialogShowing = false;
  }
}
