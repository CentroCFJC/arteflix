class VideoItem {
  final String id;
  final String name;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? duration;
  final String? description;

  const VideoItem({
    required this.id,
    required this.name,
    required this.videoUrl,
    this.thumbnailUrl,
    this.duration,
    this.description,
  });
}
