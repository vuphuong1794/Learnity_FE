import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import '../screen/intro.dart';

void main() {
  runApp(LearnityApp());
}

class LearnityApp extends StatelessWidget {
  const LearnityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: IntroScreen(), 
    );
  }
}
