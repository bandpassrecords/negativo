import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/film_roll.dart';
import '../models/exposure.dart';
import '../services/hive_service.dart';
import 'developed_gallery_screen.dart';

class RevealGalleryScreen extends StatefulWidget {
  final FilmRoll filmRoll;

  const RevealGalleryScreen({super.key, required this.filmRoll});

  @override
  State<RevealGalleryScreen> createState() => _RevealGalleryScreenState();
}

class _RevealGalleryScreenState extends State<RevealGalleryScreen> {
  late final List<Exposure> _exposures;
  late final Set<String> _revealedSet;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _exposures = HiveService.getExposuresForRoll(widget.filmRoll.id);
    _revealedSet = Set.from(widget.filmRoll.revealedExposureIds);
    final firstUnrevealed =
        _exposures.indexWhere((e) => !_revealedSet.contains(e.id));
    _currentIndex = firstUnrevealed < 0 ? 0 : firstUnrevealed;
  }

  void _onFrameRevealed(String exposureId) {
    setState(() => _revealedSet.add(exposureId));
    _persist();
  }

  Future<void> _persist() async {
    widget.filmRoll.revealedExposureIds = _revealedSet.toList();
    await HiveService.saveFilmRoll(widget.filmRoll);
  }

  void _goNext() {
    if (_currentIndex < _exposures.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _openGallery();
    }
  }

  Future<void> _skipAll() async {
    for (final e in _exposures) {
      _revealedSet.add(e.id);
    }
    widget.filmRoll.revealedExposureIds = _revealedSet.toList();
    await HiveService.saveFilmRoll(widget.filmRoll);
    if (mounted) _openGallery();
  }

  void _openGallery() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DevelopedGalleryScreen(filmRoll: widget.filmRoll),
      ),
    );
  }

  bool get _currentIsRevealed =>
      _exposures.isEmpty ||
      _revealedSet.contains(_exposures[_currentIndex].id);

  @override
  Widget build(BuildContext context) {
    if (_exposures.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openGallery());
      return const Scaffold(backgroundColor: Colors.black);
    }

    final exposure = _exposures[_currentIndex];
    final isLast = _currentIndex == _exposures.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.galleryFrameOf(exposure.order, _exposures.length),
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: _skipAll,
            child: Text(
              AppLocalizations.of(context)!.revealSkipAll,
              style: const TextStyle(color: Color(0xFFD4A853)),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          if (_currentIsRevealed && (details.primaryVelocity ?? 0) < -250) {
            _goNext();
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          child: _RevealFrame(
            key: ValueKey(exposure.id),
            exposure: exposure,
            initiallyRevealed: _revealedSet.contains(exposure.id),
            hasNext: !isLast,
            onRevealed: () => _onFrameRevealed(exposure.id),
            onNext: _goNext,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RevealFrame extends StatefulWidget {
  final Exposure exposure;
  final bool initiallyRevealed;
  final bool hasNext;
  final VoidCallback onRevealed;
  final VoidCallback onNext;

  const _RevealFrame({
    super.key,
    required this.exposure,
    required this.initiallyRevealed,
    required this.hasNext,
    required this.onRevealed,
    required this.onNext,
  });

  @override
  State<_RevealFrame> createState() => _RevealFrameState();
}

class _RevealFrameState extends State<_RevealFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _tapped = false;
  bool _expanded = false;

  static const _negativeMatrix = <double>[
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ];

  @override
  void initState() {
    super.initState();
    _tapped = widget.initiallyRevealed;
    _expanded = widget.initiallyRevealed;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      value: widget.initiallyRevealed ? 1.0 : 0.0,
    );
    if (!widget.initiallyRevealed) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _expanded = true);
          widget.onRevealed();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reveal() {
    if (_tapped) return;
    setState(() => _tapped = true);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final val = _controller.value;
            final isFront = val < 0.5;

            final frontAngle = val * pi;
            final backAngle = (val - 1) * pi;

            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOut,
                width: _expanded ? screen.width : screen.width * 0.78,
                child: GestureDetector(
                  onTap: isFront && !_tapped ? _reveal : null,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(isFront ? frontAngle : backAngle),
                    alignment: Alignment.center,
                    child: isFront
                        ? _buildNegativeSide(context)
                        : _buildRealSide(context),
                  ),
                ),
              ),
            );
          },
        ),
        if (!_tapped) _buildTapHint(context),
        if (_expanded) _buildBottomHint(context),
      ],
    );
  }

  Widget _buildNegativeSide(BuildContext context) {
    final file = File(widget.exposure.imagePath);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FilmStrip(),
        AspectRatio(
          aspectRatio: 3 / 2,
          child: file.existsSync()
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ColorFiltered(
                      colorFilter:
                          const ColorFilter.matrix(_negativeMatrix),
                      child: Image.file(file, fit: BoxFit.cover),
                    ),
                    Container(
                      color: const Color(0xFFB8660A).withValues(alpha: 0.18),
                    ),
                  ],
                )
              : Container(
                  color: const Color(0xFF3A1A00),
                  child: const Icon(
                    Icons.photo_outlined,
                    color: Color(0xFF6B3A00),
                    size: 48,
                  ),
                ),
        ),
        _FilmStrip(),
      ],
    );
  }

  Widget _buildRealSide(BuildContext context) {
    final file = File(widget.exposure.imagePath);
    if (!file.existsSync()) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Icon(Icons.broken_image_outlined,
              color: Colors.white24, size: 64),
        ),
      );
    }
    return Image.file(file, fit: BoxFit.contain);
  }

  Widget _buildTapHint(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Positioned(
      bottom: 52,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            l.galleryFrameLabel(widget.exposure.order),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white30, fontSize: 11),
          ),
          const SizedBox(height: 8),
          _PulsingText(
            text: l.revealTapToDevelop,
            style: const TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 15,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomHint(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.hasNext) {
      return Positioned(
        bottom: 36,
        left: 0,
        right: 0,
        child: GestureDetector(
          onTap: widget.onNext,
          child: Column(
            children: [
              const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
              const SizedBox(height: 4),
              Text(
                l.revealSwipeForNext,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white30, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    return Positioned(
      bottom: 36,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: widget.onNext,
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Color(0xFFD4A853), size: 22),
            const SizedBox(height: 6),
            Text(
              l.revealAllDeveloped,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFD4A853),
                  fontSize: 13,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              l.revealTapToOpenGallery,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FilmStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      color: const Color(0xFF161616),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: List.generate(
          13,
          (i) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF3D3D3D),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _PulsingText({required this.text, required this.style});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(widget.text, textAlign: TextAlign.center, style: widget.style),
    );
  }
}
