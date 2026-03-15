import 'package:flutter/material.dart';
import '../../models/page_element.dart';
import '../../theme/whisper_colors.dart';

class TextElement extends StatefulWidget {
  final PageElement element;
  final bool isSelected;
  final bool isEditing;
  final ValueChanged<String> onChanged;

  const TextElement({
    super.key,
    required this.element,
    required this.isSelected,
    required this.isEditing,
    required this.onChanged,
  });

  @override
  State<TextElement> createState() => _TextElementState();
}

class _TextElementState extends State<TextElement> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.element.data['text'] ?? '');
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(TextElement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !oldWidget.isEditing) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _focusNode.requestFocus();
      });
    } else if (!widget.isEditing && oldWidget.isEditing) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(
        widget.element.data['color'] as int? ?? WhisperColors.ink.value);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        maxLines: null,
        enabled: widget.isEditing,
        style: TextStyle(
          fontSize: widget.element.data['fontSize'] as double? ?? 16.0,
          color: color,
          height: 1.6,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}