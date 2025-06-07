import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

const String agoraAppId = '74615a0a702944e397850115fd11e31a';
const String agoraToken = ''; // Test không cần token

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final int uid;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.uid,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late final RtcEngine _engine;
  final List<int> _remoteUids = [];
  bool _isMicMuted = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: agoraAppId));

    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint('Local user ${connection.localUid} joined');
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUids.add(remoteUid);
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteUids.remove(remoteUid);
          });
        },
      ),
    );

    await _engine.startPreview();
    await _engine.joinChannel(
      token: agoraToken,
      channelId: widget.channelName,
      uid: widget.uid,
      options: const ChannelMediaOptions(),
    );

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _leaveChannel();
    super.dispose();
  }

  Future<void> _leaveChannel() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  Widget _renderRemoteVideo() {
    if (_remoteUids.isEmpty) {
      return const Center(
        child: Text(
          'Đang chờ người tham gia khác...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: _remoteUids[0]),
        connection: RtcConnection(channelId: widget.channelName),
      ),
    );
  }

  Widget _renderLocalPreview() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: SizedBox(
        width: 120,
        height: 160,
        child: AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      ),
    );
  }

  Widget _renderControlButtons() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.red,
            radius: 25,
            child: IconButton(
              icon: const Icon(Icons.call_end, color: Colors.white),
              onPressed: () {
                _leaveChannel();
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 20),
          CircleAvatar(
            backgroundColor: Colors.black54,
            radius: 25,
            child: IconButton(
              icon: const Icon(Icons.switch_camera, color: Colors.white),
              onPressed: () => _engine.switchCamera(),
            ),
          ),
          const SizedBox(width: 20),
          CircleAvatar(
            backgroundColor: Colors.black54,
            radius: 25,
            child: IconButton(
              icon: Icon(
                _isMicMuted ? Icons.mic_off : Icons.mic,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() => _isMicMuted = !_isMicMuted);
                _engine.muteLocalAudioStream(_isMicMuted);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _renderRemoteVideo(),
          _renderLocalPreview(),
          _renderControlButtons(),
        ],
      ),
    );
  }
}
