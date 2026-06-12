import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_item.dart';
import 'player_screen.dart';

class DetailScreen extends StatelessWidget {
  final VideoItem video;

  const DetailScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FocusTraversalGroup(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 48),
                      _buildThumbnail(),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          video.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (video.duration != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Duración: ${video.duration}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _PlayButton(onPressed: () => _play(context)),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (video.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: video.thumbnailUrl!,
          width: 520,
          height: 320,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildPlaceholder(),
          errorWidget: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 520,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.movie_outlined, color: Colors.grey, size: 64),
    );
  }

  void _play(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(video: video)),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PlayButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow, size: 40),
        label: const Text('Reproducir', style: TextStyle(fontSize: 26)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE50914),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
