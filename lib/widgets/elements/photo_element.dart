import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/page_element.dart';

class PhotoElement extends StatelessWidget {
  final PageElement element;

  const PhotoElement({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    final path = element.data['path'] as String?;
    if (path == null) return const SizedBox();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        width: element.size.width,
        height: element.size.height,
        fit: BoxFit.cover,
      ),
    );
  }
}