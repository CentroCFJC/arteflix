import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/video_item.dart';
import 'video_card.dart';

class CategoryRow extends StatefulWidget {
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
  State<CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<CategoryRow> {
  bool _hasHiddenLeft = false;
  bool _hasHiddenRight = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGradients());
  }

  @override
  void didUpdateWidget(CategoryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
      _updateGradients();
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    _updateGradients();
  }

  void _updateGradients() {
    final ctrl = widget.scrollController;
    if (ctrl != null && ctrl.hasClients) {
      final hasLeft = ctrl.offset > 0;
      final hasRight = ctrl.offset < ctrl.position.maxScrollExtent;
      if (hasLeft != _hasHiddenLeft || hasRight != _hasHiddenRight) {
        setState(() {
          _hasHiddenLeft = hasLeft;
          _hasHiddenRight = hasRight;
        });
      }
    }
  }

  void _scrollToCenter(int index, ScrollController controller) {
    if (!controller.hasClients) return;
    const double itemWidth = 440;
    const double paddingStart = 48;
    final double viewportWidth = controller.position.viewportDimension;
    if (viewportWidth <= 0) return;
    final double itemCenter = paddingStart + (index + 0.5) * itemWidth;
    final double targetOffset = itemCenter - viewportWidth / 2;
    final double clampedOffset = targetOffset.clamp(
      0.0,
      controller.position.maxScrollExtent,
    );
    controller.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.scrollController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(48, 20, 0, 16),
          child: Text(
            widget.category.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 310,
          child: Stack(
            children: [
              ListView(
                controller: ctrl,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.hardEdge,
                padding: const EdgeInsets.symmetric(horizontal: 48),
                children: widget.category.videos.asMap().entries.map((e) {
                  final video = e.value;
                  final index = e.key;

                  VoidCallback? onLeft;
                  if (index > 0 && widget.videoFocusNodes != null && index < widget.videoFocusNodes!.length) {
                    final prevNode = widget.videoFocusNodes![index - 1];
                    onLeft = () {
                      prevNode.requestFocus();
                      if (ctrl != null) {
                        _scrollToCenter(index - 1, ctrl);
                      }
                    };
                  }

                  VoidCallback? onRight;
                  if (index < widget.category.videos.length - 1 && widget.videoFocusNodes != null && index + 1 < widget.videoFocusNodes!.length) {
                    final nextNode = widget.videoFocusNodes![index + 1];
                    onRight = () {
                      nextNode.requestFocus();
                      if (ctrl != null) {
                        _scrollToCenter(index + 1, ctrl);
                      }
                    };
                  }

                  return _FocusableVideoCard(
                    key: ValueKey('${widget.category.id}_$index'),
                    video: video,
                    onSelected: () => widget.onVideoSelected(video),
                    autofocus: widget.initialFocus && index == 0,
                    focusNode: widget.videoFocusNodes != null && index < widget.videoFocusNodes!.length
                        ? widget.videoFocusNodes![index]
                        : null,
                    onUp: widget.upCallbacks != null && index < widget.upCallbacks!.length
                        ? widget.upCallbacks![index]
                        : null,
                    onDown: widget.downCallbacks != null && index < widget.downCallbacks!.length
                        ? widget.downCallbacks![index]
                        : null,
                    onLeft: onLeft,
                    onRight: onRight,
                    isFirst: index == 0,
                    isLast: index == widget.category.videos.length - 1,
                  );
                }).toList(),
              ),
              if (ctrl != null) ...[
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 100,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _hasHiddenLeft ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withAlpha(230),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 100,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _hasHiddenRight ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              Colors.black.withAlpha(230),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
        if (widget.onRight == null && event.logicalKey == LogicalKeyboardKey.arrowRight) {
          return KeyEventResult.handled;
        }
        if (widget.onLeft == null && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            widget.onLeft!();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.onRight!();
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
