import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/page_element.dart';
import '../../theme/whisper_colors.dart';

class VoiceElement extends StatefulWidget {
  final PageElement element;

  const VoiceElement({super.key, required this.element});

  @override
  State<VoiceElement> createState() => _VoiceElementState();
}

class _VoiceElementState extends State<VoiceElement> {
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
      if (mounted) setState(() => _position = pos);
    });
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) setState(() {
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