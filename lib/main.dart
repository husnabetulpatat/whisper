import 'package:flutter/material.dart';
import 'theme/whisper_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const WhisperApp());
}

class WhisperApp extends StatelessWidget {
  const WhisperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whisper',
      debugShowCheckedModeBanner: false,
      theme: WhisperTheme.light,
      home: const HomeScreen(),
    );
  }
}