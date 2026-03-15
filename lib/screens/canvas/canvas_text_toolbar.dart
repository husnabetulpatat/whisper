import 'package:flutter/material.dart';
import '../../models/page_element.dart';
import '../../theme/whisper_colors.dart';

class CanvasTextToolbar extends StatelessWidget {
  final PageElement element;
  final bool isEditing;
  final int backgroundColor;
  final VoidCallback onColorPicker;
  final VoidCallback onToggleEditing;
  final VoidCallback onDelete;
  final VoidCallback onFontIncrease;
  final VoidCallback onFontDecrease;

  const CanvasTextToolbar({
    super.key,
    required this.element,
    required this.isEditing,
    required this.backgroundColor,
    required this.onColorPicker,
    required this.onToggleEditing,
    required this.onDelete,
    required this.onFontIncrease,
    required this.onFontDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 52,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        color: Color(backgroundColor),
        child: Row(
          children: [
            GestureDetector(
              onTap: onColorPicker,
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Color(element.data['color'] ??
                          WhisperColors.ink.value),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: WhisperColors.divider, width: 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('color',
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: onFontDecrease,
              child: const Icon(Icons.text_decrease,
                  size: 18, color: WhisperColors.inkLight),
            ),
            const SizedBox(width: 12),
            Text(
              '${(element.data['fontSize'] as double? ?? 16.0).toInt()}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onFontIncrease,
              child: const Icon(Icons.text_increase,
                  size: 18, color: WhisperColors.inkLight),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onToggleEditing,
              child: Icon(
                isEditing ? Icons.edit_off : Icons.edit,
                size: 18,
                color: isEditing
                    ? WhisperColors.accent
                    : WhisperColors.inkLight,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline,
                  size: 18, color: Color(0xFFE07070)),
            ),
          ],
        ),
      ),
    );
  }
}