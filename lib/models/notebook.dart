import 'package:flutter/material.dart';
import 'whisper_page.dart';

class Notebook {
  final String id;
  String name;
  Color color;
  final DateTime createdAt;
  DateTime updatedAt;
  List<WhisperPage> pages;

  Notebook({
    required this.id,
    required this.name,
    this.color = const Color(0xFF8C7F9E),
    required this.createdAt,
    required this.updatedAt,
    List<WhisperPage>? pages,
  }) : pages = pages ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pages': pages.map((p) => p.toJson()).toList(),
  };

  factory Notebook.fromJson(Map<String, dynamic> json) => Notebook(
    id: json['id'],
    name: json['name'],
    color: Color(json['color']),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    pages: (json['pages'] as List)
        .map((p) => WhisperPage.fromJson(p))
        .toList(),
  );
}