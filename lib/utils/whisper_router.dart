import 'package:flutter/material.dart';
import '../models/whisper_page.dart';
import '../models/notebook.dart';
import '../screens/canvas/canvas_screen.dart';
import '../screens/notebook_screen.dart';

class WhisperRouter {
  WhisperRouter._();

  static Route toCanvas(WhisperPage page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => CanvasScreen(page: page),
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Route toNotebook(Notebook notebook, VoidCallback onChanged) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => NotebookScreen(
        notebook: notebook,
        onChanged: onChanged,
      ),
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}