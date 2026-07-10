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
              style: TextStyle(color: Colors.white70, fontSize: 22),
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
            const Icon(Icons.error_outline, color: Colors.red, size: 80),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 24)),
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
    final sh = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 48),
      child: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            height: sh * 0.09,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
          const Spacer(),
          Image.network(
            'https://res.cloudinary.com/dqgd5r847/image/upload/v1781198321/logo_cauce_blanco_completo_kgcj3s.png',
            height: sh * 0.075,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
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
    final sh = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        heroContent,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: sh * 0.12,
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
    final sh = MediaQuery.of(context).size.height;
    return Container(
      width: double.infinity,
      height: sh * 0.48,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/cabecera.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHeroVideo() {
    final sh = MediaQuery.of(context).size.height;
    final video = _selectedVideo!;
    return SizedBox(
      height: sh * 0.48,
      child: Stack(
        children: [
          _buildHeroVideoBackground(video, sh),
          Positioned(
            left: 56,
            right: 56,
            bottom: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: sh * 0.055),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Text(
                          video.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sh * 0.038,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (video.description != null && video.description!.isNotEmpty) ...[
                        SizedBox(height: sh * 0.012),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Text(
                            video.description!,
                            style: TextStyle(
                              color: Colors.white.withAlpha(178),
                              fontSize: sh * 0.022,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      SizedBox(height: sh * 0.022),
                      _HeroActionButton(
                        focusNode: _playButtonFocus,
                        autofocus: true,
                        onPressed: () => _playVideo(video),
                        icon: Icons.play_arrow,
                        label: 'Reproducir',
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

  Widget _buildHeroVideoBackground(VideoItem video, double sh) {
    final thumb = video.thumbnailUrl;
    if (thumb != null) {
      return CachedNetworkImage(
        imageUrl: thumb,
        width: double.infinity,
      height: sh * 0.48,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildHeroFallback(),
      );
    }
    return _buildHeroFallback();
  }

  Widget _buildHeroFallback() {
    final sh = MediaQuery.of(context).size.height;
    return Container(
      width: double.infinity,
      height: sh * 0.48,
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
    final sh = MediaQuery.of(context).size.height;
    return Positioned(
      top: sh * 0.07,
      right: sh * 0.03,
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
            width: MediaQuery.of(context).size.width * 0.28,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
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
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFE50914),
                            radius: 28,
                            child: Text('A',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text('Artes para la Paz',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(color: Colors.white12),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: const Text(
                        'Artes para la Paz es una apuesta por transformar vidas a través del arte, '
                        'la cultura y los saberes. Es el programa de educación y formación artística '
                        'más grande y ambicioso en la historia del país, liderado por el Ministerio '
                        'de las Culturas, las Artes y los Saberes.',
                        style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: const Text(
                        'Entre 2023 y 2026 se ofertaron más de 1.349.469 cupos que permitieron '
                        'que niñas, niños, jóvenes y adolescentes han encontrado en Artes para '
                        'la Paz un espacio para aprender, crear, expresarse, y construir '
                        'esperanza desde el arte.',
                        style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextButton(
                          onPressed: () => setState(() => _showProfilePanel = false),
                          child: const Text('Cerrar',
                              style: TextStyle(
                                  color: Color(0xFFE50914),
                                  fontSize: 18,
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
  final FocusNode? focusNode;
  final bool autofocus;

  const _HeroActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.focusNode,
    this.autofocus = false,
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
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowRight)) {
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.height * 0.028, vertical: MediaQuery.of(context).size.height * 0.013),
          decoration: BoxDecoration(
            color: _isFocused ? const Color(0xFFE50914) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
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
                  size: MediaQuery.of(context).size.height * 0.025,
                  color: _isFocused ? Colors.white : Colors.black),
              const SizedBox(width: 12),
              Text(widget.label,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height * 0.019,
                    fontWeight: FontWeight.w600,
                    color: _isFocused ? Colors.white : Colors.black,
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
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        if (!focused && widget.expanded) {
          widget.onPressed();
        }
      },
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight) {
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onDownPressed?.call();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Builder(builder: (ctx) {
          final s = MediaQuery.of(ctx).size.height * 0.045;
          final o = MediaQuery.of(ctx).size.height * 0.013;
          return Container(
          width: s * 1.6,
          height: s * 1.6,
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
                Text('A',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: s * 0.55,
                        fontWeight: FontWeight.bold,
                        height: 1)),
                Icon(
                  widget.expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                  size: o * 1.2,
                ),
              ],
            ),
          ),
        );
        }),
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
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      ),
      child: const Text('Reintentar',
          style: TextStyle(color: Colors.white, fontSize: 20)),
    );
  }
}
