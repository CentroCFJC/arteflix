import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_item.dart';

class VideoCard extends StatelessWidget {
  final VideoItem video;
  final double width;
  final double height;
  final bool isFocused;

  const VideoCard({
    super.key,
    required this.video,
    this.width = 420,
    this.height = 260,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isFocused
            ? Border.all(color: Colors.white, width: 3)
            : Border.all(color: Colors.transparent, width: 3),
        boxShadow: isFocused
            ? [BoxShadow(
                color: Colors.white.withAlpha(80),
                blurRadius: 18,
                spreadRadius: 4,
              )]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildThumbnail(),
            if (isFocused)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: Colors.black.withAlpha(180),
                  child: Text(
                    video.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      return CachedNetworkImage(
        imageUrl: video.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildPlaceholder(),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(Icons.movie_outlined, color: Colors.grey, size: 56),
      ),
    );
  }
}
