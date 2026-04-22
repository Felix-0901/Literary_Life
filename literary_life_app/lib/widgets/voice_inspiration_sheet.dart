import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../config/theme.dart';
import '../providers/cycle_provider.dart';
import '../providers/inspiration_provider.dart';
import '../services/api_service.dart';

enum _VoiceStage { idle, recording, recorded, transcribing }

class VoiceInspirationSheet extends StatefulWidget {
  const VoiceInspirationSheet({super.key});

  @override
  State<VoiceInspirationSheet> createState() => _VoiceInspirationSheetState();
}

class _VoiceInspirationSheetState extends State<VoiceInspirationSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  _VoiceStage _stage = _VoiceStage.idle;
  String? _recordingPath;
  Duration _elapsed = Duration.zero;
  Timer? _elapsedTimer;
  StreamSubscription<PlayerState>? _playerStateSub;
  bool _isPlaying = false;
  String? _error;

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    _recorder.dispose();
    _deleteRecordingFile();
    super.dispose();
  }

  Future<void> _deleteRecordingFile() async {
    final path = _recordingPath;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Swallow — the file may already be gone.
    }
    _recordingPath = null;
  }

  Future<void> _startRecording() async {
    setState(() => _error = null);
    final hasPermission = await _ensureMicrophonePermission();
    if (!hasPermission) return;

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _recordingPath = path;
      _elapsed = Duration.zero;
      _elapsedTimer?.cancel();
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed += const Duration(seconds: 1));
      });
      setState(() => _stage = _VoiceStage.recording);
    } catch (e) {
      setState(() => _error = '無法開始錄音：$e');
    }
  }

  Future<void> _stopRecording() async {
    _elapsedTimer?.cancel();
    try {
      final path = await _recorder.stop();
      if (path != null) _recordingPath = path;
      setState(() => _stage = _VoiceStage.recorded);
    } catch (e) {
      setState(() {
        _error = '錄音停止失敗：$e';
        _stage = _VoiceStage.idle;
      });
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;
    if (!mounted) return false;
    setState(() => _error = '需要麥克風權限才能錄音');
    return false;
  }

  Future<void> _togglePlayback() async {
    final path = _recordingPath;
    if (path == null) return;
    try {
      if (_isPlaying) {
        await _player.pause();
        return;
      }
      if (_player.audioSource == null) {
        await _player.setFilePath(path);
        _playerStateSub ??= _player.playerStateStream.listen((state) {
          if (!mounted) return;
          final playing = state.playing && state.processingState != ProcessingState.completed;
          if (state.processingState == ProcessingState.completed) {
            _player.seek(Duration.zero);
            _player.pause();
          }
          setState(() => _isPlaying = playing);
        });
      }
      await _player.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '播放失敗：$e');
    }
  }

  Future<void> _resetRecording() async {
    await _player.stop();
    await _deleteRecordingFile();
    if (!mounted) return;
    setState(() {
      _stage = _VoiceStage.idle;
      _elapsed = Duration.zero;
      _isPlaying = false;
      _error = null;
    });
  }

  Future<void> _transcribeAndSave() async {
    final path = _recordingPath;
    if (path == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final inspirationProvider = context.read<InspirationProvider>();
    final cycleId = context.read<CycleProvider>().currentCycle?.id;

    setState(() {
      _stage = _VoiceStage.transcribing;
      _error = null;
    });

    try {
      await _player.stop();
      final result = await ApiService.transcribeInspiration(File(path));
      final success = await inspirationProvider.createInspiration(
        cycleId: cycleId,
        eventTime: DateTime.now(),
        objectOrEvent: result.title,
        detailText: result.transcript,
      );
      await _deleteRecordingFile();

      if (!mounted) return;
      if (success) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('靈感已記錄 ✦', style: GoogleFonts.notoSansTc()),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        setState(() {
          _stage = _VoiceStage.recorded;
          _error = inspirationProvider.error ?? '靈感儲存失敗';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _VoiceStage.recorded;
        _error = '$e';
      });
    }
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '語音記錄',
                    style: GoogleFonts.notoSerifTc(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  IconButton(
                    tooltip: '關閉',
                    onPressed: _stage == _VoiceStage.transcribing
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _VoiceStage.idle:
        return _buildIdle();
      case _VoiceStage.recording:
        return _buildRecording();
      case _VoiceStage.recorded:
        return _buildRecorded();
      case _VoiceStage.transcribing:
        return _buildTranscribing();
    }
  }

  Widget _buildIdle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '按下麥克風即可錄下一段靈感，\n錄音會在轉成文字後自動刪除。',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansTc(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 24),
        _buildCircleButton(
          icon: Icons.mic_rounded,
          color: AppTheme.accent,
          onTap: _startRecording,
          label: '開始錄音',
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.notoSansTc(color: AppTheme.error, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildRecording() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingDot(),
        const SizedBox(height: 12),
        Text(
          _formatDuration(_elapsed),
          style: GoogleFonts.robotoMono(
            fontSize: 28,
            color: AppTheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        _buildCircleButton(
          icon: Icons.stop_rounded,
          color: AppTheme.error,
          onTap: _stopRecording,
          label: '結束錄音',
        ),
      ],
    );
  }

  Widget _buildRecorded() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _togglePlayback,
              iconSize: 36,
              icon: Icon(
                _isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_elapsed),
              style: GoogleFonts.robotoMono(
                fontSize: 18,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: _resetRecording,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('重錄', style: GoogleFonts.notoSansTc()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: BorderSide(color: AppTheme.divider),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _transcribeAndSave,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text('記錄', style: GoogleFonts.notoSansTc()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: GoogleFonts.notoSansTc(color: AppTheme.error, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildTranscribing() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.accent),
          const SizedBox(height: 16),
          Text(
            '拾字 AI 正在聆聽與整理...',
            style: GoogleFonts.notoSansTc(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 88,
              height: 88,
              child: Icon(icon, size: 44, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.notoSansTc(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = 0.85 + 0.25 * _controller.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.error,
            ),
          ),
        );
      },
    );
  }
}
