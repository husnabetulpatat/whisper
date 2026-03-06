import 'page_element.dart';

class WhisperPage {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  List<PageElement> elements;
  bool showDateLabel;
  int backgroundColor;

  WhisperPage({
    required this.id,
    this.title = '',
    required this.createdAt,
    required this.updatedAt,
    List<PageElement>? elements,
    this.showDateLabel = true,
    this.backgroundColor = 0xFFFDFBF8,
  }) : elements = elements ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'elements': elements.map((e) => e.toJson()).toList(),
    'showDateLabel': showDateLabel,
    'backgroundColor': backgroundColor,
  };

  factory WhisperPage.fromJson(Map<String, dynamic> json) => WhisperPage(
    id: json['id'],
    title: json['title'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    elements: (json['elements'] as List)
        .map((e) => PageElement.fromJson(e))
        .toList(),
    showDateLabel: json['showDateLabel'] ?? true,
    backgroundColor: json['backgroundColor'] ?? 0xFFFDFBF8,
  );
}