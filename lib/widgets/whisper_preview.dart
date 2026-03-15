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
          painter: _PreviewPainter(
            page: page,
            previewSize: Size(width, height),
          ),
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

    const scale = 0.25;
    return Stack(
      children: photos.map((e) {
        final path = e.data['path'] as String?;
        if (path == null) return const SizedBox();
        return Positioned(
          left: e.position.dx * scale,
          top: e.position.dy * scale,
          child: Opacity(
            opacity: e.opacity,
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
          ),
        );
      }).toList(),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final WhisperPage page;
  final Size previewSize;

  const _PreviewPainter({
    required this.page,
    required this.previewSize,
  });

  static const double scale = 0.25;

  @override
  void paint(Canvas canvas, Size size) {
    // Arka plan
    final bgPaint = Paint()..color = Color(page.backgroundColor);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    for (final element in page.elements) {
      switch (element.type) {
        case PageElementType.text:
          _drawText(canvas, element);
          break;
        case PageElementType.drawing:
          _drawStrokes(canvas, element);
          break;
        case PageElementType.musicCard:
          _drawMusicCard(canvas, element);
          break;
        case PageElementType.voiceRecording:
          _drawVoiceCard(canvas, element);
          break;
        default:
          break;
      }
    }

    canvas.restore();
  }

  void _drawText(Canvas canvas, PageElement element) {
    final text = element.data['text'] as String? ?? '';
    if (text.isEmpty || text == 'write something...') return;

    final color = Color(
        element.data['color'] as int? ?? WhisperColors.ink.value);
    final fontSize =
    ((element.data['fontSize'] as double? ?? 16.0) * scale)
        .clamp(4.0, 12.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color.withOpacity(element.opacity),
          height: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
    );

    textPainter.layout(maxWidth: element.size.width * scale);

    canvas.save();
    canvas.translate(element.position.dx * scale, element.position.dy * scale);
    canvas.rotate(element.rotation);
    canvas.scale(element.scale);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawStrokes(Canvas canvas, PageElement element) {
    final strokesData = element.data['strokes'] as List?;
    if (strokesData == null) return;

    for (final s in strokesData) {
      final points = (s['points'] as List)
          .map((p) => Offset(
        p['dx'].toDouble() * scale,
        p['dy'].toDouble() * scale,
      ))
          .toList();

      if (points.isEmpty) continue;

      final isEraser = s['brush'] == 'eraser';
      final paint = Paint()
        ..strokeWidth = (s['width'] as num).toDouble() * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (isEraser) {
        paint.blendMode = BlendMode.clear;
        paint.color = Colors.transparent;
      } else {
        paint.color = Color(s['color'] as int);
      }

      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length - 1; i++) {
        final mid = Offset(
          (points[i].dx + points[i + 1].dx) / 2,
          (points[i].dy + points[i + 1].dy) / 2,
        );
        path.quadraticBezierTo(
            points[i].dx, points[i].dy, mid.dx, mid.dy);
      }
      if (points.length > 1) {
        path.lineTo(points.last.dx, points.last.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawMusicCard(Canvas canvas, PageElement element) {
    final x = element.position.dx * scale;
    final y = element.position.dy * scale;
    final w = element.size.width * scale;
    const h = 20.0 * scale;

    final paint = Paint()
      ..color = WhisperColors.surface
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(4),
      ),
      paint,
    );

    final platformName = element.data['platform'] as String? ?? 'unknown';
    Color platformColor = WhisperColors.inkFaint;
    if (platformName == 'spotify') platformColor = const Color(0xFF1DB954);
    if (platformName == 'appleMusic') platformColor = const Color(0xFFFC3C44);
    if (platformName == 'youtubeMusic') platformColor = const Color(0xFFFF0000);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 3 * scale, h),
        const Radius.circular(2),
      ),
      Paint()..color = platformColor,
    );
  }

  void _drawVoiceCard(Canvas canvas, PageElement element) {
    final x = element.position.dx * scale;
    final y = element.position.dy * scale;
    final w = element.size.width * scale;
    const h = 18.0 * scale;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(4),
      ),
      Paint()
        ..color = WhisperColors.accentSoft.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.page != page;
}