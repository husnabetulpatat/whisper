import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:just_audio/just_audio.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/whisper_page.dart';
import '../models/page_element.dart';
import '../theme/whisper_colors.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/voice_recorder.dart';
import '../widgets/music_card.dart';
import '../services/permission_service.dart';

class CanvasScreen extends StatefulWidget {
  final WhisperPage page;

  const CanvasScreen({super.key, required this.page});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  PageElement? _selectedElement;
  bool _drawingMode = false;
  final GlobalKey<DrawingCanvasState> _drawingKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  List<DrawnStroke> _strokes = [];
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    final existing = widget.page.elements
        .where((e) => e.type == PageElementType.drawing)
        .toList();
    if (existing.isNotEmpty) {
      _strokes = _deserializeStrokes(existing.first.data);
    }
  }

  List<DrawnStroke> _deserializeStrokes(Map<String, dynamic> data) {
    final list = data['strokes'] as List?;
    if (list == null) return [];
    return list.map((s) {
      final points = (s['points'] as List)
          .map((p) => Offset(p['dx'].toDouble(), p['dy'].toDouble()))
          .toList();
      return DrawnStroke(
        points: points,
        color: Color(s['color']),
        width: s['width'].toDouble(),
        brush: BrushType.values.byName(s['brush']),
      );
    }).toList();
  }

  Map<String, dynamic> _serializeStrokes(List<DrawnStroke> strokes) {
    return {
      'strokes': strokes.map((s) => {
        'points': s.points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
        'color': s.color.value,
        'width': s.width,
        'brush': s.brush.name,
      }).toList(),
    };
  }

  void _saveStrokes(List<DrawnStroke> strokes) {
    setState(() {
      _strokes = strokes;
      final existing = widget.page.elements
          .where((e) => e.type == PageElementType.drawing)
          .toList();
      if (existing.isNotEmpty) {
        existing.first.data = _serializeStrokes(strokes);
      } else {
        widget.page.elements.add(PageElement(
          id: 'drawing_layer',
          type: PageElementType.drawing,
          position: Offset.zero,
          size: Size.zero,
          data: _serializeStrokes(strokes),
        ));
      }
    });
  }

  void _deleteElement(PageElement element) {
    setState(() {
      widget.page.elements.remove(element);
      _selectedElement = null;
    });
  }

  void _addTextElement() {
    final now = DateTime.now();
    final element = PageElement(
      id: now.millisecondsSinceEpoch.toString(),
      type: PageElementType.text,
      position: const Offset(40, 120),
      size: const Size(280, 120),
      data: {
        'text': 'write something...',
        'fontSize': 16.0,
        'color': WhisperColors.ink.value,
      },
    );
    setState(() {
      _drawingMode = false;
      widget.page.elements.add(element);
      _selectedElement = element;
    });
  }

  Future<void> _addPhotoElement() async {
    final granted = await PermissionService.requestGalleryPermission();

    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('gallery permission needed'),
            backgroundColor: WhisperColors.inkLight,
            action: SnackBarAction(
              label: 'settings',
              textColor: Colors.white,
              onPressed: () => PermissionService.openSettings(),
            ),
          ),
        );
      }
      return;
    }

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '',
          toolbarColor: const Color(0xFFF7F4F0),
          toolbarWidgetColor: const Color(0xFF2C2A27),
          backgroundColor: const Color(0xFFF7F4F0),
          activeControlsWidgetColor: const Color(0xFF8C7F9E),
          hideBottomControls: false,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: '',
          cancelButtonTitle: 'cancel',
          doneButtonTitle: 'done',
        ),
      ],
    );

    if (croppedFile == null) return;

    final imageFile = File(croppedFile.path);
    final decodedImage =
    await decodeImageFromList(await imageFile.readAsBytes());
    final imageWidth = decodedImage.width.toDouble();
    final imageHeight = decodedImage.height.toDouble();

    const maxWidth = 280.0;
    final ratio = maxWidth / imageWidth;
    final displayHeight = imageHeight * ratio;

    final now = DateTime.now();
    final element = PageElement(
      id: now.millisecondsSinceEpoch.toString(),
      type: PageElementType.photo,
      position: const Offset(40, 120),
      size: Size(maxWidth, displayHeight),
      data: {'path': croppedFile.path},
    );
    setState(() {
      widget.page.elements.add(element);
    });
  }

  void _addVoiceElement() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VoiceRecorderSheet(
        onRecordingComplete: (path, duration) {
          final now = DateTime.now();
          final element = PageElement(
            id: now.millisecondsSinceEpoch.toString(),
            type: PageElementType.voiceRecording,
            position: const Offset(40, 120),
            size: const Size(280, 72),
            data: {
              'path': path,
              'duration': duration.inSeconds,
            },
          );
          setState(() {
            widget.page.elements.add(element);
          });
        },
      ),
    );
  }

  void _addMusicCard() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MusicCardSheet(
        onCardAdded: (data) {
          final now = DateTime.now();
          final element = PageElement(
            id: now.millisecondsSinceEpoch.toString(),
            type: PageElementType.musicCard,
            position: const Offset(40, 120),
            size: const Size(280, 76),
            data: data,
          );
          setState(() {
            widget.page.elements.add(element);
          });
        },
      ),
    );
  }

  void _toggleDrawingMode() {
    setState(() {
      _drawingMode = !_drawingMode;
      _selectedElement = null;
    });
  }

  Future<void> _exportAndShare() async {
    setState(() {
      _selectedElement = null;
      _drawingMode = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    final image = await _screenshotController.capture(pixelRatio: 3.0);
    if (image == null) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/whisper_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(image);

    await Share.shareXFiles(
      [XFile(path)],
      text: 'made with whisper. ✦',
    );
  }

  void _showBackgroundPicker() {
    final colors = [
      const Color(0xFFFDFBF8),
      const Color(0xFFF7F4F0),
      const Color(0xFFF0EBE3),
      const Color(0xFFE8E4DD),
      const Color(0xFFE8EDF0),
      const Color(0xFFEAE8F0),
      const Color(0xFFE8F0EA),
      const Color(0xFF2C2A27),
      const Color(0xFF1A1A2E),
      const Color(0xFF1C2B1E),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: WhisperColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('canvas color',
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) {
                final isSelected =
                    widget.page.backgroundColor == color.value;
                return GestureDetector(
                  onTap: () {
                    setState(() => widget.page.backgroundColor = color.value);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                          color: WhisperColors.accent, width: 2.5)
                          : Border.all(
                          color: WhisperColors.divider, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextColorPicker(PageElement element) {
    final colors = [
      WhisperColors.ink,
      WhisperColors.inkLight,
      WhisperColors.inkFaint,
      const Color(0xFFFFFFFF),
      const Color(0xFF8C7F9E),
      const Color(0xFF5C7A6B),
      const Color(0xFF7A5C6B),
      const Color(0xFF5C6B7A),
      const Color(0xFFBFA980),
      const Color(0xFFE07070),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: WhisperColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('text color',
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) {
                final currentColor = Color(
                    element.data['color'] ?? WhisperColors.ink.value);
                final isSelected = currentColor.value == color.value;
                return GestureDetector(
                  onTap: () {
                    setState(() => element.data['color'] = color.value);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                          color: WhisperColors.accent, width: 2.5)
                          : Border.all(
                          color: WhisperColors.divider, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(widget.page.backgroundColor),
      body: SafeArea(
        child: Stack(
          children: [
            Screenshot(
              controller: _screenshotController,
              child: _buildElementsLayer(),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_drawingMode,
                child: DrawingCanvas(
                  key: _drawingKey,
                  initialStrokes: _strokes,
                  onStrokesChanged: _saveStrokes,
                ),
              ),
            ),
            _buildTopBar(),
            if (_drawingMode) _buildDrawingToolbar(),
            if (!_drawingMode) _buildBottomToolbar(),
            if (_selectedElement?.type == PageElementType.text &&
                !_drawingMode)
              _buildTextToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios,
                size: 18,
                color: WhisperColors.inkLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.page.title.isEmpty
                    ? 'untitled whisper'
                    : widget.page.title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            GestureDetector(
              onTap: _showBackgroundPicker,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Color(widget.page.backgroundColor),
                  shape: BoxShape.circle,
                  border:
                  Border.all(color: WhisperColors.divider, width: 1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _exportAndShare,
              child: const Icon(
                Icons.ios_share,
                size: 18,
                color: WhisperColors.inkLight,
              ),
            ),
            const SizedBox(width: 12),
            if (widget.page.showDateLabel)
              Text(
                _formatDateTime(widget.page.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextToolbar() {
    final element = _selectedElement!;
    return Positioned(
      top: 52,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        color: Color(widget.page.backgroundColor),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showTextColorPicker(element),
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
              onTap: () {
                setState(() {
                  final current =
                      element.data['fontSize'] as double? ?? 16.0;
                  element.data['fontSize'] =
                      (current - 2).clamp(10.0, 48.0);
                });
              },
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
              onTap: () {
                setState(() {
                  final current =
                      element.data['fontSize'] as double? ?? 16.0;
                  element.data['fontSize'] =
                      (current + 2).clamp(10.0, 48.0);
                });
              },
              child: const Icon(Icons.text_increase,
                  size: 18, color: WhisperColors.inkLight),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _deleteElement(element),
              child: const Icon(Icons.delete_outline,
                  size: 18, color: Color(0xFFE07070)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementsLayer() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _selectedElement = null),
        child: Container(
          color: Color(widget.page.backgroundColor),
          child: Stack(
            children: widget.page.elements
                .where((e) => e.type != PageElementType.drawing)
                .map((element) => _buildElement(element))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildElement(PageElement element) {
    if (_drawingMode) {
      return Positioned(
        left: element.position.dx,
        top: element.position.dy,
        child: Transform.rotate(
          angle: element.rotation,
          child: Transform.scale(
            scale: element.scale,
            child: element.type == PageElementType.photo
                ? _buildElementContent(element, false)
                : SizedBox(
              width: element.size.width,
              child: _buildElementContent(element, false),
            ),
          ),
        ),
      );
    }

    final isSelected = _selectedElement?.id == element.id;
    const hitPadding = 20.0;

    return Positioned(
      left: element.position.dx - hitPadding,
      top: element.position.dy - hitPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => setState(() => _selectedElement = element),
        onLongPress: () => _confirmDelete(element),
        onScaleStart: (details) {
          _baseScale = element.scale;
          _baseRotation = element.rotation;
        },
        onScaleUpdate: (details) {
          setState(() {
            if (details.pointerCount == 1) {
              element.position = Offset(
                element.position.dx + details.focalPointDelta.dx,
                element.position.dy + details.focalPointDelta.dy,
              );
            } else {
              element.scale =
                  (_baseScale * details.scale).clamp(0.3, 5.0);
              element.rotation =
                  _baseRotation + (details.rotation * 0.8);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(hitPadding),
          child: Transform.rotate(
            angle: element.rotation,
            child: Transform.scale(
              scale: element.scale,
              child: Container(
                width: element.type == PageElementType.photo
                    ? null
                    : element.size.width,
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(
                      color: WhisperColors.accentSoft,
                      width: element.type == PageElementType.photo
                          ? 1.5
                          : 1.0)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildElementContent(element, isSelected),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(PageElement element) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: WhisperColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('delete this element?',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: WhisperColors.divider, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('cancel',
                            style: TextStyle(
                                fontSize: 13,
                                color: WhisperColors.inkLight)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _deleteElement(element);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE07070).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('delete',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE07070))),
                      ),
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

  Widget _buildElementContent(PageElement element, bool isSelected) {
    switch (element.type) {
      case PageElementType.text:
        return _TextElement(
          element: element,
          isSelected: isSelected,
          onChanged: (val) => setState(() => element.data['text'] = val),
        );
      case PageElementType.photo:
        return _PhotoElement(element: element);
      case PageElementType.voiceRecording:
        return _VoiceElement(element: element);
      case PageElementType.musicCard:
        return MusicCardWidget(data: element.data);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomToolbar() {
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
            _ToolbarButton(
              icon: Icons.text_fields,
              label: 'text',
              onTap: _addTextElement,
            ),
            _ToolbarButton(
              icon: Icons.draw_outlined,
              label: 'draw',
              onTap: _toggleDrawingMode,
              isActive: _drawingMode,
            ),
            _ToolbarButton(
              icon: Icons.photo_outlined,
              label: 'photo',
              onTap: _addPhotoElement,
            ),
            _ToolbarButton(
              icon: Icons.mic_none,
              label: 'voice',
              onTap: _addVoiceElement,
            ),
            _ToolbarButton(
              icon: Icons.music_note_outlined,
              label: 'music',
              onTap: _addMusicCard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingToolbar() {
    final state = _drawingKey.currentState;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BrushButton(
                  label: 'pen',
                  isActive: state?.currentBrush == BrushType.pen,
                  onTap: () => setState(() => state?.setBrush(BrushType.pen)),
                ),
                _BrushButton(
                  label: 'pencil',
                  isActive: state?.currentBrush == BrushType.pencil,
                  onTap: () =>
                      setState(() => state?.setBrush(BrushType.pencil)),
                ),
                _BrushButton(
                  label: 'marker',
                  isActive: state?.currentBrush == BrushType.marker,
                  onTap: () =>
                      setState(() => state?.setBrush(BrushType.marker)),
                ),
                _BrushButton(
                  label: 'highlight',
                  isActive: state?.currentBrush == BrushType.highlighter,
                  onTap: () =>
                      setState(() => state?.setBrush(BrushType.highlighter)),
                ),
                _BrushButton(
                  label: 'eraser',
                  isActive: state?.currentBrush == BrushType.eraser,
                  onTap: () =>
                      setState(() => state?.setBrush(BrushType.eraser)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _drawingKey.currentState?.undo()),
                  child: const Icon(Icons.undo,
                      color: WhisperColors.inkLight, size: 22),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () =>
                      setState(() => _drawingKey.currentState?.redo()),
                  child: const Icon(Icons.redo,
                      color: WhisperColors.inkLight, size: 22),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () =>
                      setState(() => _drawingKey.currentState?.clear()),
                  child: const Icon(Icons.delete_outline,
                      color: WhisperColors.inkLight, size: 22),
                ),
                const Spacer(),
                _colorDot(WhisperColors.ink),
                _colorDot(const Color(0xFF5C7A6B)),
                _colorDot(const Color(0xFF7A5C6B)),
                _colorDot(const Color(0xFF5C6B7A)),
                _colorDot(const Color(0xFFBFA980)),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleDrawingMode,
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

  Widget _colorDot(Color color) {
    final isSelected = _drawingKey.currentState?.currentColor == color;
    return GestureDetector(
      onTap: () => setState(() => _drawingKey.currentState?.setColor(color)),
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

  String _formatDateTime(DateTime dt) {
    final months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}  ·  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _VoiceElement extends StatefulWidget {
  final PageElement element;
  const _VoiceElement({required this.element});

  @override
  State<_VoiceElement> createState() => _VoiceElementState();
}

class _VoiceElementState extends State<_VoiceElement> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final path = widget.element.data['path'] as String?;
    if (path == null) return;
    await _player.setFilePath(path);
    setState(() {
      _duration = _player.duration ?? Duration.zero;
    });
    _player.positionStream.listen((pos) {
      setState(() => _position = pos);
    });
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        _player.seek(Duration.zero);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      width: widget.element.size.width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WhisperColors.accentSoft.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (_isPlaying) {
                await _player.pause();
                setState(() => _isPlaying = false);
              } else {
                await _player.play();
                setState(() => _isPlaying = true);
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: WhisperColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: WhisperColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        WhisperColors.accent),
                    minHeight: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(_position)} / ${_fmt(_duration)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: WhisperColors.inkFaint,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoElement extends StatelessWidget {
  final PageElement element;
  const _PhotoElement({required this.element});

  @override
  Widget build(BuildContext context) {
    final path = element.data['path'] as String?;
    if (path == null) return const SizedBox();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        width: element.size.width,
        height: element.size.height,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _TextElement extends StatefulWidget {
  final PageElement element;
  final bool isSelected;
  final ValueChanged<String> onChanged;

  const _TextElement({
    required this.element,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  State<_TextElement> createState() => _TextElementState();
}

class _TextElementState extends State<_TextElement> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.element.data['text'] ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
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
        onChanged: widget.onChanged,
        maxLines: null,
        enabled: widget.isSelected,
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