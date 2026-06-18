import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../models/video_item.dart';

class PlayerScreen extends StatefulWidget {
  final VideoItem video;

  const PlayerScreen({super.key, required this.video});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _showControls = true;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _controlsAutoHide = Duration(seconds: 5);
  Timer? _hideControlsTimer;

  void _showControlsWithTimer() {
    _hideControlsTimer?.cancel();
    setState(() => _showControls = true);
    _hideControlsTimer = Timer(_controlsAutoHide, () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _initAndroidPlayer();
    }
  }

  Future<void> _initAndroidPlayer() async {
    while (_retryCount < _maxRetries) {
      try {
        debugPrint('[Arteflix] Intento ${_retryCount + 1}/$_maxRetries — Cargando: ${widget.video.videoUrl}');
        final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));
        _controller = ctrl;
        await ctrl.initialize();
        ctrl.addListener(_onPlayerStateChanged);
        if (!mounted) return;
        debugPrint('[Arteflix] Video inicializado correctamente');
        setState(() => _initialized = true);
        ctrl.play();
        _showControlsWithTimer();
        return;
      } catch (e) {
        debugPrint('[Arteflix] Error en intento ${_retryCount + 1}: $e');
        _controller?.dispose();
        _controller = null;
        _retryCount++;
        if (!mounted) return;
        if (_retryCount < _maxRetries) {
          final delay = Duration(seconds: _retryCount * 2);
          debugPrint('[Arteflix] Reintentando en ${delay.inSeconds}s...');
          await Future.delayed(delay);
        } else {
          debugPrint('[Arteflix] Todos los intentos fallaron');
          _showError(
            'No se pudo reproducir el video después de $_maxRetries intentos.\n\n'
            'Esto puede deberse a un problema con el decoder de video del televisor '
            'o la conexión a Google Drive.\n\n'
            'Detalle: $e',
          );
        }
      }
    }
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final c = _controller!;
    setState(() {});
    if (c.value.isInitialized &&
        c.value.position == c.value.duration &&
        !c.value.isPlaying) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_onPlayerStateChanged);
    _controller?.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_initialized) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause ||
        event.logicalKey == LogicalKeyboardKey.select) {
      _showControlsWithTimer();
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final pos = _controller!.value.position;
      final newPos = Duration(milliseconds: (pos.inMilliseconds - 5000).clamp(0, _controller!.value.duration.inMilliseconds));
      _controller!.seekTo(newPos);
      _showControlsWithTimer();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final pos = _controller!.value.position;
      final newPos = Duration(milliseconds: (pos.inMilliseconds + 5000).clamp(0, _controller!.value.duration.inMilliseconds));
      _controller!.seekTo(newPos);
      _showControlsWithTimer();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (!_showControls) _showControlsWithTimer();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.mediaStop) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: _initialized ? _buildPlayer() : _buildLoading(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildDesktopFallback(),
    );
  }

  Widget _buildDesktopFallback() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tv, color: Colors.white54, size: 100),
          const SizedBox(height: 32),
          const Text(
            'Reproductor disponible solo en Android TV',
            style: TextStyle(color: Colors.white70, fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            widget.video.name,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Abrir en el navegador'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
          ),
            const SizedBox(height: 20),
            TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Volver al catálogo',
              style: TextStyle(color: Colors.white54, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.video.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Preparando video...',
            style: TextStyle(color: Colors.white70, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (_showControls) {
              _hideControlsTimer?.cancel();
              setState(() => _showControls = false);
            } else {
              _showControlsWithTimer();
            }
          },
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
        if (_showControls) _buildControlsOverlay(),
      ],
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withAlpha(180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFFE50914),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ControlButton(
                  icon: _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  onPressed: () {
                    _showControlsWithTimer();
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                  },
                ),
                const SizedBox(width: 24),
                Text(
                  _formatDuration(_controller!.value.position),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const Spacer(),
                Text(
                  _formatDuration(_controller!.value.duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _retry() async {
    _retryCount = 0;
    setState(() => _initialized = false);
    _initAndroidPlayer();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _retry();
            },
            child: const Text('Reintentar', style: TextStyle(color: Color(0xFFE50914))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Volver', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 40),
        onPressed: onPressed,
        splashRadius: 28,
      ),
    );
  }
}
