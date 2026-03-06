import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/whisper_colors.dart';
import '../services/permission_service.dart';

class VoiceRecorderSheet extends StatefulWidget {
  final void Function(String path, Duration duration) onRecordingComplete;

  const VoiceRecorderSheet({
    super.key,
    required this.onRecordingComplete,
  });

  @override
  State<VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<VoiceRecorderSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  Duration _recordDuration = Duration.zero;
  Duration _playPosition = Duration.zero;
  Duration _playDuration = Duration.zero;

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final granted = await PermissionService.requestMicrophonePermission();
    if (!granted) return;

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/whisper_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _recordDuration = Duration.zero;
    });

    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) return false;
      setState(() {
        _recordDuration += const Duration(seconds: 1);
      });
      return _isRecording;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    setState(() {
      _isRecording = false;
      _hasRecording = true;
    });
    await _loadAudio();
  }

  Future<void> _loadAudio() async {
    if (_recordingPath == null) return;
    await _player.setFilePath(_recordingPath!);
    setState(() {
      _playDuration = _player.duration ?? Duration.zero;
    });
    _player.positionStream.listen((pos) {
      setState(() => _playPosition = pos);
    });
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _playPosition = Duration.zero;
        });
        _player.seek(Duration.zero);
      }
    });
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.play();
      setState(() => _isPlaying = true);
    }
  }

  void _confirmRecording() {
    if (_recordingPath != null) {
      widget.onRecordingComplete(_recordingPath!, _recordDuration);
      Navigator.pop(context);
    }
  }

  void _discardRecording() {
    if (_recordingPath != null) {
      File(_recordingPath!).deleteSync();
    }
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _recordDuration = Duration.zero;
      _playPosition = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: const BoxDecoration(
        color: WhisperColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _hasRecording ? 'voice whisper' : 'record a whisper',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 32),
          if (!_hasRecording) _buildRecordView(),
          if (_hasRecording) _buildPlaybackView(),
        ],
      ),
    );
  }

  Widget _buildRecordView() {
    return Column(
      children: [
        Text(
          _formatDuration(_recordDuration),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w200,
            color: WhisperColors.ink,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _isRecording
                  ? const Color(0xFFE07070)
                  : WhisperColors.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isRecording ? 'tap to stop' : 'tap to record',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildPlaybackView() {
    final progress = _playDuration.inMilliseconds > 0
        ? _playPosition.inMilliseconds / _playDuration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _togglePlayback,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: WhisperColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
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
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDuration(_playPosition)} / ${_formatDuration(_playDuration)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: _discardRecording,
              child: Column(
                children: [
                  const Icon(Icons.delete_outline,
                      color: WhisperColors.inkFaint, size: 24),
                  const SizedBox(height: 4),
                  Text('discard',
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            GestureDetector(
              onTap: _confirmRecording,
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: WhisperColors.accent, size: 24),
                  const SizedBox(height: 4),
                  Text('add to whisper',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: WhisperColors.accent,
                      )),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}