import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/whisper_colors.dart';

enum MusicPlatform { spotify, appleMusic, youtubeMusic, unknown }

class MusicCardSheet extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onCardAdded;

  const MusicCardSheet({super.key, required this.onCardAdded});

  @override
  State<MusicCardSheet> createState() => _MusicCardSheetState();
}

class _MusicCardSheetState extends State<MusicCardSheet> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  String? _error;

  MusicPlatform _detectPlatform(String url) {
    if (url.contains('spotify.com') || url.contains('spotify:')) {
      return MusicPlatform.spotify;
    } else if (url.contains('music.apple.com')) {
      return MusicPlatform.appleMusic;
    } else if (url.contains('music.youtube.com') ||
        url.contains('youtube.com') ||
        url.contains('youtu.be')) {
      return MusicPlatform.youtubeMusic;
    }
    return MusicPlatform.unknown;
  }

  String _extractFallbackTitle(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final last = segments.last;
        return last
            .replaceAll('-', ' ')
            .replaceAll('_', ' ')
            .split('?')
            .first;
      }
    } catch (_) {}
    return 'unknown track';
  }

  void _addCard() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'paste a link first');
      return;
    }

    final platform = _detectPlatform(url);
    if (platform == MusicPlatform.unknown) {
      setState(() => _error = 'only spotify, apple music or youtube music');
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? _extractFallbackTitle(url)
        : _titleController.text.trim();

    widget.onCardAdded({
      'url': url,
      'title': title,
      'platform': platform.name,
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        decoration: const BoxDecoration(
          color: WhisperColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('add music',
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              autofocus: true,
              style: const TextStyle(
                fontSize: 13,
                color: WhisperColors.ink,
              ),
              decoration: InputDecoration(
                hintText: 'paste spotify / apple music / youtube link',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: WhisperColors.inkFaint,
                ),
                errorText: _error,
                enabledBorder: const UnderlineInputBorder(
                  borderSide:
                  BorderSide(color: WhisperColors.divider, width: 1),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide:
                  BorderSide(color: WhisperColors.accent, width: 1),
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 13,
                color: WhisperColors.ink,
              ),
              decoration: const InputDecoration(
                hintText: 'song name (optional)',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: WhisperColors.inkFaint,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide:
                  BorderSide(color: WhisperColors.divider, width: 1),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide:
                  BorderSide(color: WhisperColors.accent, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _addCard,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: WhisperColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'add to whisper',
                    style: TextStyle(
                      fontSize: 13,
                      color: WhisperColors.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MusicCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const MusicCardWidget({super.key, required this.data});

  MusicPlatform get _platform {
    final name = data['platform'] as String? ?? 'unknown';
    return MusicPlatform.values.byName(name);
  }

  Color get _platformColor {
    switch (_platform) {
      case MusicPlatform.spotify:
        return const Color(0xFF1DB954);
      case MusicPlatform.appleMusic:
        return const Color(0xFFFC3C44);
      case MusicPlatform.youtubeMusic:
        return const Color(0xFFFF0000);
      case MusicPlatform.unknown:
        return WhisperColors.inkLight;
    }
  }

  IconData get _platformIcon {
    switch (_platform) {
      case MusicPlatform.spotify:
        return Icons.music_note;
      case MusicPlatform.appleMusic:
        return Icons.apple;
      case MusicPlatform.youtubeMusic:
        return Icons.play_circle_outline;
      case MusicPlatform.unknown:
        return Icons.music_note_outlined;
    }
  }

  String get _platformName {
    switch (_platform) {
      case MusicPlatform.spotify:
        return 'Spotify';
      case MusicPlatform.appleMusic:
        return 'Apple Music';
      case MusicPlatform.youtubeMusic:
        return 'YouTube Music';
      case MusicPlatform.unknown:
        return 'Music';
    }
  }

  Future<void> _openLink() async {
    final url = data['url'] as String?;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'unknown track';

    return GestureDetector(
      onTap: _openLink,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WhisperColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WhisperColors.divider, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _platformColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _platformIcon,
                color: _platformColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: WhisperColors.ink,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _platformName,
                    style: TextStyle(
                      fontSize: 11,
                      color: _platformColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new,
              size: 14,
              color: WhisperColors.inkFaint,
            ),
          ],
        ),
      ),
    );
  }
}