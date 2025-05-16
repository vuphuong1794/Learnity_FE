import 'package:flutter/material.dart';
import '../screen/intro.dart';

void main() {
  runApp(LearnityApp());
}

class LearnityApp extends StatelessWidget {
  const LearnityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IntroScreen(), 
    );
  }
}
