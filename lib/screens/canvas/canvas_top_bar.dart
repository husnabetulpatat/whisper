import 'package:flutter/material.dart';
import '../../models/whisper_page.dart';
import '../../theme/whisper_colors.dart';

class CanvasTopBar extends StatelessWidget {
  final WhisperPage page;
  final VoidCallback onBack;
  final VoidCallback onBackgroundPicker;
  final VoidCallback onExport;

  const CanvasTopBar({
    super.key,
    required this.page,
    required this.onBack,
    required this.onBackgroundPicker,
    required this.onExport,
  });

  String _formatDateTime(DateTime dt) {
    final months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}  ·  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: const Icon(
                Icons.arrow_back_ios,
                size: 18,
                color: WhisperColors.inkLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                page.title.isEmpty ? 'untitled whisper' : page.title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            GestureDetector(
              onTap: onBackgroundPicker,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Color(page.backgroundColor),
                  shape: BoxShape.circle,
                  border: Border.all(color: WhisperColors.divider, width: 1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onExport,
              child: const Icon(
                Icons.ios_share,
                size: 18,
                color: WhisperColors.inkLight,
              ),
            ),
            const SizedBox(width: 12),
            if (page.showDateLabel)
              Text(
                _formatDateTime(page.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }
}