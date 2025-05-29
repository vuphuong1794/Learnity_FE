import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('🔙 [Background] Title: ${message.notification?.title}');
  print('🔙 [Background] Body: ${message.notification?.body}');
  print('🔙 [Background] Data: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // iOS: Yêu cầu quyền
    await _firebaseMessaging.requestPermission();

    // Lấy FCM token
    final fCMToken = await _firebaseMessaging.getToken();
    print('🔥 FCM Token: $fCMToken');

    // Android local noti setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);

    // Foreground handler
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          0,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default Channel',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }

      print('📩 [Foreground] Title: ${notification?.title}');
      print('📩 [Foreground] Body: ${notification?.body}');
      print('📩 [Foreground] Data: ${message.data}');
    });

    // Opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('📤 App opened from background via notification');
      print('Title: ${message.notification?.title}');
    });
  }
}
