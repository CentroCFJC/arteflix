import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/category.dart';
import '../models/video_item.dart';
import '../services/google_drive_service.dart';
import '../widgets/category_row.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleDriveService _driveService = GoogleDriveService();
  final FocusNode _heroFocus = FocusNode();
  final FocusNode _profileFocus = FocusNode();
  final FocusNode _playButtonFocus = FocusNode();
  List<Category> _categories = [];
  List<List<FocusNode>> _videoFocusGrid = [];
  List<ScrollController> _hScrollControllers = [];
  final ScrollController _verticalScrollController = ScrollController();
  final List<GlobalKey> _categoryKeys = [];
  bool _loading = true;
  String? _error;
  bool _showProfilePanel = false;
  VideoItem? _selectedVideo;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categories = await _driveService.fetchCatalog();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoryKeys
          ..clear()
          ..addAll(categories.map((_) => GlobalKey()));
        _videoFocusGrid = categories.map((cat) =>
          List.generate(cat.videos.length, (_) => FocusNode())
        ).toList();
        _hScrollControllers = categories.map((_) => ScrollController()).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar el catálogo';
        _loading = false;
      });
    }
  }

  void _selectVideo(VideoItem video) {
    setState(() => _selectedVideo = video);
    Future.microtask(() => _playButtonFocus.requestFocus());
  }

  void _playVideo(VideoItem video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(video: video)),
    );
  }

  @override
  void dispose() {
    _heroFocus.dispose();
    _profileFocus.dispose();
    _playButtonFocus.dispose();
    _verticalScrollController.dispose();
    for (final row in _videoFocusGrid) {
      for (final node in row) {
        node.dispose();
      }
    }
    for (final ctrl in _hScrollControllers) {
      ctrl.dispose();
    }
    _driveService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedVideo == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedVideo != null) {
          setState(() => _selectedVideo = null);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Cargando catálogo...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 24),
            _RetryButton(onRetry: _loadCatalog),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              _buildHeroBanner(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _verticalScrollController,
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: _categories.asMap().entries.map((e) {
                      final catIndex = e.key;
                      final rowNodes = _videoFocusGrid.length > catIndex
                          ? _videoFocusGrid[catIndex]
                          : <FocusNode>[];
                      final isLast = catIndex == _categories.length - 1;

                      final prevNodes = catIndex > 0 ? _videoFocusGrid[catIndex - 1] : null;
                      final nextNodes = !isLast && _videoFocusGrid.length > catIndex + 1
                          ? _videoFocusGrid[catIndex + 1]
                          : null;

                      final List<VoidCallback?> upCbs;
                      if (catIndex == 0) {
                        final upNode = _selectedVideo != null ? _playButtonFocus : _profileFocus;
                        upCbs = rowNodes.map((_) => () => upNode.requestFocus()).toList();
                      } else if (prevNodes != null && prevNodes.isNotEmpty) {
                        final targetNode = prevNodes[0];
                        final targetCtrl = _hScrollControllers[catIndex - 1];
                        upCbs = rowNodes.map((_) => () {
                          if (targetCtrl.hasClients) targetCtrl.jumpTo(0);
                          targetNode.requestFocus();
                          _scrollIntoView(targetNode);
                        }).toList();
                      } else {
                        upCbs = rowNodes.map((_) => null).toList();
                      }

                      final List<VoidCallback?> downCbs;
                      if (nextNodes != null && nextNodes.isNotEmpty) {
                        final targetNode = nextNodes[0];
                        final targetCtrl = _hScrollControllers[catIndex + 1];
                        downCbs = rowNodes.map((_) => () {
                          if (targetCtrl.hasClients) targetCtrl.jumpTo(0);
                          targetNode.requestFocus();
                          _scrollIntoView(targetNode);
                        }).toList();
                      } else {
                        downCbs = rowNodes.map((_) => null).toList();
                      }

                      return CategoryRow(
                        key: _categoryKeys[catIndex],
                        category: e.value,
                        onVideoSelected: _selectVideo,
                        initialFocus: catIndex == 0,
                        videoFocusNodes: rowNodes,
                        upCallbacks: upCbs,
                        downCallbacks: downCbs,
                        scrollController: _hScrollControllers[catIndex],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: _buildTopBar(),
        ),
        if (_showProfilePanel) _buildProfilePanel(),
      ],
    );
  }

  void _scrollIntoView(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCategoryRow(node);
    });
  }

  void _scrollToCategoryRow(FocusNode node) {
    for (int i = 0; i < _videoFocusGrid.length; i++) {
      if (_videoFocusGrid[i].contains(node) && i < _categoryKeys.length) {
        final key = _categoryKeys[i];
        if (key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            alignment: 0.0,
            duration: const Duration(milliseconds: 200),
          );
        }
        break;
      }
    }
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40),
      child: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            height: 96,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),
          Image.network(
            'https://res.cloudinary.com/dqgd5r847/image/upload/v1781198321/logo_cauce_blanco_completo_kgcj3s.png',
            height: 60,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          _ProfileButton(
            expanded: _showProfilePanel,
            focusNode: _profileFocus,
            onPressed: () => setState(() => _showProfilePanel = !_showProfilePanel),
            onDownPressed: () {
              if (_selectedVideo != null) {
                _playButtonFocus.requestFocus();
              } else if (_videoFocusGrid.isNotEmpty && _videoFocusGrid[0].isNotEmpty) {
                if (_hScrollControllers.isNotEmpty) {
                  _hScrollControllers[0].jumpTo(0);
                }
                _videoFocusGrid[0][0].requestFocus();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    Widget heroContent;
    if (_selectedVideo != null) {
      heroContent = Focus(
        focusNode: _heroFocus,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.escape ||
               event.logicalKey == LogicalKeyboardKey.gameButtonB)) {
            setState(() => _selectedVideo = null);
            return KeyEventResult.handled;
          }
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _profileFocus.requestFocus();
            return KeyEventResult.handled;
          }
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (_videoFocusGrid.isNotEmpty && _videoFocusGrid[0].isNotEmpty) {
              if (_hScrollControllers.isNotEmpty) {
                _hScrollControllers[0].jumpTo(0);
              }
              _videoFocusGrid[0][0].requestFocus();
              _scrollIntoView(_videoFocusGrid[0][0]);
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: _buildHeroVideo(),
      );
    } else {
      heroContent = _buildHeroDefault();
    }
    return Stack(
      children: [
        heroContent,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 125,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroDefault() {
    return Container(
      width: double.infinity,
      height: 500,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/cabecera.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHeroVideo() {
    final video = _selectedVideo!;
    return SizedBox(
      height: 500,
      child: Stack(
        children: [
          _buildHeroVideoBackground(video),
          Positioned(
            left: 48,
            right: 48,
            bottom: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Text(
                          video.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _HeroActionButton(
                            focusNode: _playButtonFocus,
                            autofocus: true,
                            onPressed: () => _playVideo(video),
                            icon: Icons.play_arrow,
                            label: 'Reproducir',
                            primary: true,
                            isFirst: true,
                          ),
                          const SizedBox(width: 12),
                          _HeroActionButton(
                            onPressed: () {},
                            icon: Icons.info_outline,
                            label: 'Más información',
                            primary: false,
                            isLast: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroVideoBackground(VideoItem video) {
    final thumb = video.thumbnailUrl;
    if (thumb != null) {
      return CachedNetworkImage(
        imageUrl: thumb,
        width: double.infinity,
        height: 500,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildHeroFallback(),
      );
    }
    return _buildHeroFallback();
  }

  Widget _buildHeroFallback() {
    return Container(
      width: double.infinity,
      height: 500,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A1A), Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildProfilePanel() {
    return Positioned(
      top: 88,
      right: 40,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.escape ||
               event.logicalKey == LogicalKeyboardKey.gameButtonB)) {
            setState(() => _showProfilePanel = false);
            return KeyEventResult.handled;
          }
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
            setState(() => _showProfilePanel = false);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 380,
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(160),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFE50914),
                            radius: 22,
                            child: Text('A',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text('Artes para la Paz',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(color: Colors.white12),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                        'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
                        'nisi ut aliquip ex ea commodo consequat.',
                        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text(
                        'Duis aute irure dolor in reprehenderit in voluptate velit esse '
                        'cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat '
                        'cupidatat non proident, sunt in culpa qui officia deserunt mollit '
                        'anim id est laborum.',
                        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text(
                        'Sed ut perspiciatis unde omnis iste natus error sit voluptatem '
                        'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa '
                        'quae ab illo inventore veritatis et quasi architecto beatae vitae '
                        'dicta sunt explicabo.',
                        style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextButton(
                          onPressed: () => setState(() => _showProfilePanel = false),
                          child: const Text('Cerrar',
                              style: TextStyle(
                                  color: Color(0xFFE50914),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool primary;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isFirst;
  final bool isLast;

  const _HeroActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.primary,
    this.focusNode,
    this.autofocus = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<_HeroActionButton> createState() => _HeroActionButtonState();
}

class _HeroActionButtonState extends State<_HeroActionButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onPressed();
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
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: widget.primary
                ? Colors.white
                : Colors.white.withAlpha(40),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isFocused ? const Color(0xFFE50914) : Colors.transparent,
              width: 3,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFFE50914).withAlpha(120),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 24,
                  color: widget.primary ? Colors.black : Colors.white),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.primary ? Colors.black : Colors.white,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatefulWidget {
  final bool expanded;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final VoidCallback? onDownPressed;

  const _ProfileButton({
    required this.expanded,
    required this.onPressed,
    this.focusNode,
    this.onDownPressed,
  });

  @override
  State<_ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<_ProfileButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onDownPressed?.call();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE50914),
            shape: BoxShape.circle,
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                        color: Colors.white.withAlpha(80), blurRadius: 10)
                  ]
                : [],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('A',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1)),
                Icon(
                  widget.expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onRetry,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE50914),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: const Text('Reintentar',
          style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}
