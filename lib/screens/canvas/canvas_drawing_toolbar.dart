import 'package:flutter/material.dart';
import '../../theme/whisper_colors.dart';
import '../../widgets/drawing_canvas.dart';

class CanvasDrawingToolbar extends StatelessWidget {
  final GlobalKey<DrawingCanvasState> drawingKey;
  final VoidCallback onDone;
  final void Function(double) onOpacityChanged;
  final void Function(BrushType) onBrushChanged;
  final void Function(Color) onColorChanged;

  const CanvasDrawingToolbar({
    super.key,
    required this.drawingKey,
    required this.onDone,
    required this.onOpacityChanged,
    required this.onBrushChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final state = drawingKey.currentState;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: WhisperColors.surface,
          border: Border(
            top: BorderSide(color: WhisperColors.divider, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fırça seçimi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BrushButton(
                  label: 'pen',
                  isActive: state?.currentBrush == BrushType.pen,
                  onTap: () => onBrushChanged(BrushType.pen),
                ),
                _BrushButton(
                  label: 'pencil',
                  isActive: state?.currentBrush == BrushType.pencil,
                  onTap: () => onBrushChanged(BrushType.pencil),
                ),
                _BrushButton(
                  label: 'marker',
                  isActive: state?.currentBrush == BrushType.marker,
                  onTap: () => onBrushChanged(BrushType.marker),
                ),
                _BrushButton(
                  label: 'highlight',
                  isActive: state?.currentBrush == BrushType.highlighter,
                  onTap: () => onBrushChanged(BrushType.highlighter),
                ),
                _BrushButton(
                  label: 'eraser',
                  isActive: state?.currentBrush == BrushType.eraser,
                  onTap: () => onBrushChanged(BrushType.eraser),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Opacity slider
            Row(
              children: [
                const Icon(Icons.circle,
                    size: 8, color: WhisperColors.inkFaint),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 1.5,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12),
                      activeTrackColor: WhisperColors.accent,
                      inactiveTrackColor: WhisperColors.divider,
                      thumbColor: WhisperColors.accent,
                      overlayColor: WhisperColors.accentSoft,
                    ),
                    child: Slider(
                      value: state?.currentOpacity ?? 1.0,
                      min: 0.1,
                      max: 1.0,
                      onChanged: onOpacityChanged,
                    ),
                  ),
                ),
                const Icon(Icons.circle,
                    size: 14, color: WhisperColors.inkFaint),
              ],
            ),
            const SizedBox(height: 4),
            // Alt kontroller
            Row(
              children: [
                GestureDetector(
                  onTap: () => state?.undo(),
                  child: const Icon(Icons.undo,
                      color: WhisperColors.inkLight, size: 22),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => state?.redo(),
                  child: const Icon(Icons.redo,
                      color: WhisperColors.inkLight, size: 22),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => state?.clear(),
                  child: const Icon(Icons.delete_outline,
                      color: WhisperColors.inkLight, size: 22),
                ),
                const Spacer(),
                _colorDot(WhisperColors.ink, state),
                _colorDot(const Color(0xFF5C7A6B), state),
                _colorDot(const Color(0xFF7A5C6B), state),
                _colorDot(const Color(0xFF5C6B7A), state),
                _colorDot(const Color(0xFFBFA980), state),
                const Spacer(),
                GestureDetector(
                  onTap: onDone,
                  child: const Text(
                    'done',
                    style: TextStyle(
                      fontSize: 13,
                      color: WhisperColors.accent,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorDot(Color color, DrawingCanvasState? state) {
    final isSelected = state?.currentColor == color;
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: WhisperColors.accent, width: 2)
              : null,
        ),
      ),
    );
  }
}

class _BrushButton extends StatelessWidget {
  final String label;
  final bool? isActive;
  final VoidCallback onTap;

  const _BrushButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive == true
              ? WhisperColors.accentSoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive == true
                ? WhisperColors.accent
                : WhisperColors.inkFaint,
            fontWeight:
            isActive == true ? FontWeight.w500 : FontWeight.w300,
          ),
        ),
      ),
    );
  }
}