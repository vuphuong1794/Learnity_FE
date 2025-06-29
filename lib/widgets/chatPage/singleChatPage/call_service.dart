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
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final callID = data['callID'];
            final callerName = data['callerName'];
            final status = data['status'];

            if (status == 'calling') {
              _showIncomingCallDialog(callID, callerName);
            } else if (status == 'cancelled' || status == 'rejected') {
              _stopRingtone();
              _closeDialogIfOpen();
            }
          }
        });
  }

  static void _showIncomingCallDialog(String callID, String callerName) {
    if (_isDialogShowing || navigatorKey.currentContext == null) return;
    _isDialogShowing = true;
    _playRingtone();

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.background,
            title: Text('$callerName đang gọi đến'),
            content: const Text('Bạn có muốn trả lời cuộc gọi không?'),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('video_calls')
                      .doc(callID)
                      .update({'status': 'rejected'});
                  _stopRingtone();
                  _closeDialogIfOpen();
                },
                child: const Text('Từ chối'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
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
                child: const Text('Trả lời'),
              ),
            ],
          ),
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
