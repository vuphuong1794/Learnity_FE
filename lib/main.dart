import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:learnity/api/firebase_api.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:learnity/wrapper.dart';
import 'package:learnity/theme/theme_provider.dart';

//global object for accessing device screen size
late Size mq;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await dotenv.load();
  await Firebase.initializeApp();
  // Đăng ký background message handler
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  // Init Firebase API
  final firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();

  await initializeDateFormatting('vi_VN', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const Learnity(),
    ),
  );
}

class Learnity extends StatelessWidget {
  const Learnity({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Learnity',
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const Wrapper(),
    );
  }
}
