import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/whisper_page.dart';
import '../../models/page_element.dart';
import '../../theme/whisper_colors.dart';
import '../../widgets/drawing_canvas.dart';
import '../../widgets/voice_recorder.dart';
import '../../widgets/music_card.dart';
import '../../widgets/elements/text_element.dart';
import '../../widgets/elements/photo_element.dart';
import '../../widgets/elements/voice_element.dart';
import '../../services/permission_service.dart';
import 'canvas_top_bar.dart';
import 'canvas_text_toolbar.dart';
import 'canvas_bottom_toolbar.dart';
import 'canvas_drawing_toolbar.dart';

class CanvasScreen extends StatefulWidget {
  final WhisperPage page;

  const CanvasScreen({super.key, required this.page});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  PageElement? _selectedElement;
  PageElement? _editingElement;
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

  // ─── Strokes ────────────────────────────────────────────────

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

  // ─── Element İşlemleri ──────────────────────────────────────

  void _deleteElement(PageElement element) {
    setState(() {
      widget.page.elements.remove(element);
      _selectedElement = null;
      _editingElement = null;
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
      _editingElement = element;
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
            data: {'path': path, 'duration': duration.inSeconds},
          );
          setState(() => widget.page.elements.add(element));
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
          setState(() => widget.page.elements.add(element));
        },
      ),
    );
  }

  // ─── Mod Değiştirme ─────────────────────────────────────────

  void _toggleDrawingMode() {
    setState(() {
      _drawingMode = !_drawingMode;
      _selectedElement = null;
      _editingElement = null;
    });
  }

  // ─── Export ─────────────────────────────────────────────────

  Future<void> _exportAndShare() async {
    setState(() {
      _selectedElement = null;
      _editingElement = null;
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
    await Share.shareXFiles([XFile(path)], text: 'made with whisper. ✦');
  }

  // ─── Picker'lar ─────────────────────────────────────────────

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
                final isSelected = widget.page.backgroundColor == color.value;
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
                          ? Border.all(color: WhisperColors.accent, width: 2.5)
                          : Border.all(color: WhisperColors.divider, width: 1),
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
                final currentColor =
                Color(element.data['color'] ?? WhisperColors.ink.value);
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
                          ? Border.all(color: WhisperColors.accent, width: 2.5)
                          : Border.all(color: WhisperColors.divider, width: 1),
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

  // ─── Build ──────────────────────────────────────────────────

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
            CanvasTopBar(
              page: widget.page,
              onBack: () => Navigator.pop(context),
              onBackgroundPicker: _showBackgroundPicker,
              onExport: _exportAndShare,
            ),
            if (_drawingMode)
              CanvasDrawingToolbar(
                drawingKey: _drawingKey,
                onDone: _toggleDrawingMode,
              ),
            if (!_drawingMode)
              CanvasBottomToolbar(
                onText: _addTextElement,
                onDraw: _toggleDrawingMode,
                onPhoto: _addPhotoElement,
                onVoice: _addVoiceElement,
                onMusic: _addMusicCard,
                drawingMode: _drawingMode,
              ),
            if (_selectedElement?.type == PageElementType.text &&
                !_drawingMode)
              CanvasTextToolbar(
                element: _selectedElement!,
                isEditing: _editingElement?.id == _selectedElement!.id,
                backgroundColor: widget.page.backgroundColor,
                onColorPicker: () => _showTextColorPicker(_selectedElement!),
                onToggleEditing: () {
                  setState(() {
                    if (_editingElement?.id == _selectedElement!.id) {
                      _editingElement = null;
                    } else {
                      _editingElement = _selectedElement;
                    }
                  });
                },
                onDelete: () => _deleteElement(_selectedElement!),
                onFontIncrease: () {
                  setState(() {
                    final current =
                        _selectedElement!.data['fontSize'] as double? ?? 16.0;
                    _selectedElement!.data['fontSize'] =
                        (current + 2).clamp(10.0, 48.0);
                  });
                },
                onFontDecrease: () {
                  setState(() {
                    final current =
                        _selectedElement!.data['fontSize'] as double? ?? 16.0;
                    _selectedElement!.data['fontSize'] =
                        (current - 2).clamp(10.0, 48.0);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // ─── Elements Layer ─────────────────────────────────────────

  Widget _buildElementsLayer() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedElement = null;
          _editingElement = null;
        }),
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
    final isEditing = _editingElement?.id == element.id;
    const hitPadding = 20.0;

    return Positioned(
      left: element.position.dx - hitPadding,
      top: element.position.dy - hitPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => setState(() {
          _selectedElement = element;
          _editingElement = null;
        }),
        onDoubleTap: () {
          if (element.type == PageElementType.text) {
            setState(() {
              _selectedElement = element;
              _editingElement = element;
            });
          }
        },
        onLongPress: () => _confirmDelete(element),
        onScaleStart: (details) {
          if (isEditing) return;
          if (_selectedElement != null && !isSelected) return; // YENİ
          _baseScale = element.scale;
          _baseRotation = element.rotation;
        },
        onScaleUpdate: (details) {
          if (isEditing) return;
          if (_selectedElement != null && !isSelected) return; // YENİ
          setState(() {
            if (details.pointerCount == 1) {
              element.position = Offset(
                element.position.dx + details.focalPointDelta.dx,
                element.position.dy + details.focalPointDelta.dy,
              );
            } else {
              element.scale = (_baseScale * details.scale).clamp(0.3, 5.0);
              element.rotation = _baseRotation + (details.rotation * 0.8);
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
                      color: isEditing
                          ? WhisperColors.accent
                          : WhisperColors.accentSoft,
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

  Widget _buildElementContent(PageElement element, bool isSelected) {
    switch (element.type) {
      case PageElementType.text:
        return TextElement(
          element: element,
          isSelected: isSelected,
          isEditing: _editingElement?.id == element.id,
          onChanged: (val) => setState(() => element.data['text'] = val),
        );
      case PageElementType.photo:
        return PhotoElement(element: element);
      case PageElementType.voiceRecording:
        return VoiceElement(element: element);
      case PageElementType.musicCard:
        return MusicCardWidget(data: element.data);
      default:
        return const SizedBox();
    }
  }
}