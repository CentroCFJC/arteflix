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
          padding: const EdgeInsets.fromLTRB(48, 20, 0, 16),
          child: Text(
            category.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 310,
          child: ListView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.symmetric(horizontal: 48),
            children: category.videos.asMap().entries.map((e) {
              final video = e.value;
              final index = e.key;

              VoidCallback? onLeft;
              if (index > 0 && videoFocusNodes != null && index < videoFocusNodes!.length) {
                final prevNode = videoFocusNodes![index - 1];
                onLeft = () => prevNode.requestFocus();
              }

              VoidCallback? onRight;
              if (index < category.videos.length - 1 && videoFocusNodes != null && index + 1 < videoFocusNodes!.length) {
                final nextNode = videoFocusNodes![index + 1];
                onRight = () => nextNode.requestFocus();
              }

              return _FocusableVideoCard(
                key: ValueKey('${category.id}_$index'),
                video: video,
                onSelected: () => onVideoSelected(video),
                autofocus: initialFocus && index == 0,
                focusNode: videoFocusNodes != null && index < videoFocusNodes!.length
                    ? videoFocusNodes![index]
                    : null,
                onUp: upCallbacks != null && index < upCallbacks!.length
                    ? upCallbacks![index]
                    : null,
                onDown: downCallbacks != null && index < downCallbacks!.length
                    ? downCallbacks![index]
                    : null,
                onLeft: onLeft,
                onRight: onRight,
                isFirst: index == 0,
                isLast: index == category.videos.length - 1,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
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
  final VoidCallback? onLeft;
  final VoidCallback? onRight;
  final bool isFirst;
  final bool isLast;

  const _FocusableVideoCard({
    super.key,
    required this.video,
    required this.onSelected,
    this.autofocus = false,
    this.focusNode,
    this.onUp,
    this.onDown,
    this.onLeft,
    this.onRight,
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
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (widget.onLeft != null) {
              widget.onLeft!();
            }
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (widget.onRight != null) {
              widget.onRight!();
            }
            return KeyEventResult.handled;
          }
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
