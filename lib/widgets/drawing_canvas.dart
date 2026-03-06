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

  BrushType get currentBrush => _brush;
  Color get currentColor => _color;
  double get currentWidth => _width;

  Color _effectiveColor() {
    if (_brush == BrushType.eraser) return WhisperColors.surface;
    if (_brush == BrushType.highlighter) return _color.withOpacity(0.35);
    if (_brush == BrushType.pencil) return _color.withOpacity(0.6);
    return _color;
  }

  double _effectiveWidth() {
    if (_brush == BrushType.marker) return _width * 3;
    if (_brush == BrushType.highlighter) return _width * 5;
    if (_brush == BrushType.eraser) return _width * 6;
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
      child: CustomPaint(
        painter: _StrokePainter(
          strokes: _strokes,
          currentPoints: _currentPoints,
          currentColor: _effectiveColor(),
          currentWidth: _effectiveWidth(),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<DrawnStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;

  _StrokePainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  void _drawStroke(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    if (points.length > 1) {
      path.lineTo(points.last.dx, points.last.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.width);
    }
    if (currentPoints.isNotEmpty) {
      _drawStroke(canvas, currentPoints, currentColor, currentWidth);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) => true;
}