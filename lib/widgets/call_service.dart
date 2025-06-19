import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class CallService {
  static const String appId =
      'af02edb9d6674398a41450450394f77e'; // Thay bằng App ID của bạn
  static String channelName = 'test';
  static String token =
      '007eJxTYMh4Pevwa1PH3St/N/9nvLXx7uEYy1tOPUueaStVnNGWczFWYEhMMzBKTUmyTDEzMzcxtrRINDE0MTUAImNLkzRz89T69uCMhkBGhleb21gZGSAQxGdhKEktLmFgAADqFCEJ'; // Bỏ trống nếu dùng mode testing

  static Future<void> initialize() async {
    await [Permission.microphone, Permission.camera].request();
  }

  static Future<RtcEngine> createEngine() async {
    RtcEngine engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: appId));
    return engine;
  }

  static Future<void> startVoiceCall(String channel, int uid) async {
    final engine = await createEngine();
    await engine.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    await engine.joinChannel(
      token: token,
      channelId: channel,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  static Future<void> startVideoCall(String channel, int uid) async {
    final engine = await createEngine();
    await engine.enableVideo();
    await engine.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    await engine.joinChannel(
      token: token,
      channelId: channel,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  static Future<void> endCall(RtcEngine engine) async {
    await engine.leaveChannel();
    await engine.release();
  }
}
