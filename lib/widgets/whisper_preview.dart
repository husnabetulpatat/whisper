import 'package:flutter/material.dart';
import 'dart:io';
import '../models/whisper_page.dart';
import '../models/page_element.dart';
import '../theme/whisper_colors.dart';

class WhisperPreview extends StatelessWidget {
  final WhisperPage page;
  final double width;
  final double height;

  const WhisperPreview({
    super.key,
    required this.page,
    this.width = 280,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _PreviewPainter(page: page, size: Size(width, height)),
          child: _buildPhotoLayer(),
        ),
      ),
    );
  }

  Widget _buildPhotoLayer() {
    final photos = page.elements
        .where((e) => e.type == PageElementType.photo)
        .toList();

    if (photos.isEmpty) return const SizedBox();

    return Stack(
      children: photos.map((e) {
        final path = e.data['path'] as String?;
        if (path == null) return const SizedBox();

        const scale = 0.25;
        return Positioned(
          left: e.position.dx * scale,
          top: e.position.dy * scale,
          child: Transform.rotate(
            angle: e.rotation,
            child: Transform.scale(
              scale: e.scale * scale,
              alignment: Alignment.topLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(path),
                  width: e.size.width,
                  height: e.size.height,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final WhisperPage page;
  final Size size;

  const _PreviewPainter({required this.page, required this.size});

  @override
  void paint(Canvas canvas, Size size) {
    // Arka plan
    final bgPaint = Paint()..color = Color(page.backgroundColor);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    const scale = 0.25;

    for (final element in page.elements) {
      if (element.type == PageElementType.text) {
        _drawText(canvas, element, scale);
      } else if (element.type == PageElementType.musicCard) {
        _drawMusicCard(canvas, element, scale);
      } else if (element.type == PageElementType.voiceRecording) {
        _drawVoiceCard(canvas, element, scale);
      }
    }
  }

  void _drawText(Canvas canvas, PageElement element, double scale) {
    final text = element.data['text'] as String? ?? '';
    if (text.isEmpty || text == 'write something...') return;

    final color = Color(
        element.data['color'] as int? ?? WhisperColors.ink.value);
    final fontSize =
    ((element.data['fontSize'] as double? ?? 16.0) * scale)
        .clamp(4.0, 12.0);

    final x = element.position.dx * scale;
    final y = element.position.dy * scale;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          height: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
    );

    textPainter.layout(maxWidth: element.size.width * scale);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(element.rotation);
    canvas.scale(element.scale);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawMusicCard(Canvas canvas, PageElement element, double scale) {
    final x = element.position.dx * scale;
    final y = element.position.dy * scale;
    final w = element.size.width * scale;
    final h = 20.0 * scale;

    final paint = Paint()
      ..color = WhisperColors.surface
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, paint);

    // Platform renk çizgisi
    final platformName = element.data['platform'] as String? ?? 'unknown';
    Color platformColor = WhisperColors.inkFaint;
    if (platformName == 'spotify') platformColor = const Color(0xFF1DB954);
    if (platformName == 'appleMusic') platformColor = const Color(0xFFFC3C44);
    if (platformName == 'youtubeMusic') platformColor = const Color(0xFFFF0000);

    final linePaint = Paint()
      ..color = platformColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 3 * scale, h),
        const Radius.circular(2),
      ),
      linePaint,
    );
  }

  void _drawVoiceCard(Canvas canvas, PageElement element, double scale) {
    final x = element.position.dx * scale;
    final y = element.position.dy * scale;
    final w = element.size.width * scale;
    final h = 18.0 * scale;

    final paint = Paint()
      ..color = WhisperColors.accentSoft.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.page != page;
}