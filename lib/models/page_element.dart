import 'package:flutter/material.dart';

enum PageElementType {
  text,
  photo,
  drawing,
  voiceRecording,
  musicCard,
  video,
  sticker,
}

class PageElement {
  final String id;
  final PageElementType type;
  Offset position;
  Size size;
  double zIndex;
  double scale;
  double rotation;
  double opacity;
  Map<String, dynamic> data;

  PageElement({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    this.zIndex = 0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'position': {'dx': position.dx, 'dy': position.dy},
    'size': {'width': size.width, 'height': size.height},
    'zIndex': zIndex,
    'scale': scale,
    'rotation': rotation,
    'opacity': opacity,
    'data': data,
  };

  factory PageElement.fromJson(Map<String, dynamic> json) => PageElement(
    id: json['id'],
    type: PageElementType.values.byName(json['type']),
    position: Offset(json['position']['dx'], json['position']['dy']),
    size: Size(json['size']['width'], json['size']['height']),
    zIndex: json['zIndex'],
    scale: json['scale'] ?? 1.0,
    rotation: json['rotation'] ?? 0.0,
    opacity: json['opacity'] ?? 1.0,
    data: Map<String, dynamic>.from(json['data']),
  );
}