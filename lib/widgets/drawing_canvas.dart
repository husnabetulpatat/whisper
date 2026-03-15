import 'package:flutter/material.dart';
import '../theme/whisper_colors.dart';

enum BrushType { pen, pencil, marker, highlighter, eraser }

class DrawnStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final BrushType brush;

  DrawnStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.brush,
  });
}

class DrawingCanvas extends StatefulWidget {
  final List<DrawnStroke> initialStrokes;
  final void Function(List<DrawnStroke>)? onStrokesChanged;

  const DrawingCanvas({
    super.key,
    this.initialStrokes = const [],
    this.onStrokesChanged,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  late List<DrawnStroke> _strokes;
  final List<DrawnStroke> _undoStack = [];
  List<Offset> _currentPoints = [];

  BrushType _brush = BrushType.pen;
  Color _color = WhisperColors.ink;
  double _width = 2.0;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _strokes = List.from(widget.initialStrokes);
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _undoStack.add(_strokes.removeLast());
        widget.onStrokesChanged?.call(_strokes);
      });
    }
  }

  void redo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _strokes.add(_undoStack.removeLast());
        widget.onStrokesChanged?.call(_strokes);
      });
    }
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _undoStack.clear();
      widget.onStrokesChanged?.call(_strokes);
    });
  }

  void setBrush(BrushType brush) => setState(() => _brush = brush);
  void setColor(Color color) => setState(() => _color = color);
  void setWidth(double width) => setState(() => _width = width);
  void setOpacity(double opacity) => setState(() => _opacity = opacity);
  double get currentOpacity => _opacity;

  BrushType get currentBrush => _brush;
  Color get currentColor => _color;
  double get currentWidth => _width;

  Color _effectiveColor() {
    if (_brush == BrushType.eraser) return Colors.transparent;
    if (_brush == BrushType.highlighter) return _color.withOpacity(0.35 * _opacity);
    if (_brush == BrushType.pencil) return _color.withOpacity(0.6 * _opacity);
    return _color.withOpacity(_opacity);
  }

  double _effectiveWidth() {
    if (_brush == BrushType.marker) return _width * 3;
    if (_brush == BrushType.highlighter) return _width * 5;
    if (_brush == BrushType.eraser) return _width * 8;
    return _width;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) {
        setState(() {
          _undoStack.clear();
          _currentPoints = [d.localPosition];
        });
      },
      onPanUpdate: (d) {
        setState(() {
          _currentPoints.add(d.localPosition);
        });
      },
      onPanEnd: (_) {
        final stroke = DrawnStroke(
          points: List.from(_currentPoints),
          color: _effectiveColor(),
          width: _effectiveWidth(),
          brush: _brush,
        );
        setState(() {
          _strokes.add(stroke);
          _currentPoints = [];
          widget.onStrokesChanged?.call(_strokes);
        });
      },
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _StrokePainter(
            strokes: _strokes,
            currentPoints: _currentPoints,
            currentColor: _effectiveColor(),
            currentWidth: _effectiveWidth(),
            isEraser: _brush == BrushType.eraser,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<DrawnStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final bool isEraser;

  _StrokePainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.isEraser,
  });

  void _drawStroke(
      Canvas canvas,
      List<Offset> points,
      Color color,
      double width,
      bool eraser,
      ) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (eraser) {
      paint.blendMode = BlendMode.clear;
      paint.color = Colors.transparent;
    } else {
      paint.color = color;
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

  @override
  void paint(Canvas canvas, Size size) {
    // BlendMode.clear için saveLayer lazım
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (final stroke in strokes) {
      _drawStroke(
        canvas,
        stroke.points,
        stroke.color,
        stroke.width,
        stroke.brush == BrushType.eraser,
      );
    }

    if (currentPoints.isNotEmpty) {
      _drawStroke(
        canvas,
        currentPoints,
        currentColor,
        currentWidth,
        isEraser,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_StrokePainter old) => true;
}