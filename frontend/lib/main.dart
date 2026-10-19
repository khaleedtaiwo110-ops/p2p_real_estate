import 'package:flutter/material.dart';
import 'src/features/onboarding/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'P2P Real Estate',
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}