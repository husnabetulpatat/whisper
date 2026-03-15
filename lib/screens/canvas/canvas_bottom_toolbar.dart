import 'package:flutter/material.dart';
import '../../theme/whisper_colors.dart';

class CanvasBottomToolbar extends StatelessWidget {
  final VoidCallback onText;
  final VoidCallback onDraw;
  final VoidCallback onPhoto;
  final VoidCallback onVoice;
  final VoidCallback onMusic;
  final bool drawingMode;

  const CanvasBottomToolbar({
    super.key,
    required this.onText,
    required this.onDraw,
    required this.onPhoto,
    required this.onVoice,
    required this.onMusic,
    required this.drawingMode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: WhisperColors.surface,
          border: Border(
            top: BorderSide(color: WhisperColors.divider, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ToolbarButton(icon: Icons.text_fields, label: 'text', onTap: onText),
            _ToolbarButton(icon: Icons.draw_outlined, label: 'draw', onTap: onDraw, isActive: drawingMode),
            _ToolbarButton(icon: Icons.photo_outlined, label: 'photo', onTap: onPhoto),
            _ToolbarButton(icon: Icons.mic_none, label: 'voice', onTap: onVoice),
            _ToolbarButton(icon: Icons.music_note_outlined, label: 'music', onTap: onMusic),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? WhisperColors.accent : WhisperColors.inkLight,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? WhisperColors.accent : WhisperColors.inkFaint,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}