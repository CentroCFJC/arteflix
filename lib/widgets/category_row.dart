import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/video_item.dart';
import 'video_card.dart';

class CategoryRow extends StatelessWidget {
  final Category category;
  final ValueChanged<VideoItem> onVideoSelected;
  final bool initialFocus;
  final List<FocusNode>? videoFocusNodes;
  final List<VoidCallback?>? upCallbacks;
  final List<VoidCallback?>? downCallbacks;
  final ScrollController? scrollController;

  const CategoryRow({
    super.key,
    required this.category,
    required this.onVideoSelected,
    this.initialFocus = false,
    this.videoFocusNodes,
    this.upCallbacks,
    this.downCallbacks,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(48, 16, 0, 12),
          child: Text(
            category.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.symmetric(horizontal: 42),
            children: category.videos.asMap().entries.map((e) {
              final video = e.value;
              return _FocusableVideoCard(
                video: video,
                onSelected: () => onVideoSelected(video),
                autofocus: initialFocus && e.key == 0,
                focusNode: videoFocusNodes != null && e.key < videoFocusNodes!.length
                    ? videoFocusNodes![e.key]
                    : null,
                onUp: upCallbacks != null && e.key < upCallbacks!.length
                    ? upCallbacks![e.key]
                    : null,
                onDown: downCallbacks != null && e.key < downCallbacks!.length
                    ? downCallbacks![e.key]
                    : null,
                isFirst: e.key == 0,
                isLast: e.key == category.videos.length - 1,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FocusableVideoCard extends StatefulWidget {
  final VideoItem video;
  final VoidCallback onSelected;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final bool isFirst;
  final bool isLast;

  const _FocusableVideoCard({
    required this.video,
    required this.onSelected,
    this.autofocus = false,
    this.focusNode,
    this.onUp,
    this.onDown,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<_FocusableVideoCard> createState() => _FocusableVideoCardState();
}

class _FocusableVideoCardState extends State<_FocusableVideoCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onSelected();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp && widget.onUp != null) {
            widget.onUp!();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown && widget.onDown != null) {
            widget.onDown!();
            return KeyEventResult.handled;
          }
          if (widget.isFirst && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            return KeyEventResult.handled;
          }
          if (widget.isLast && event.logicalKey == LogicalKeyboardKey.arrowRight) {
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelected,
        child: VideoCard(
          video: widget.video,
          isFocused: _isFocused,
        ),
      ),
    );
  }
}
