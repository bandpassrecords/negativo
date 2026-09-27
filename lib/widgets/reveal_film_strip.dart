import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../effects/effect_photo.dart';
import '../effects/film_effect.dart';
import '../effects/film_strip.dart';
import '../effects/foil.dart';
import '../models/exposure.dart';

/// Index of the first frame still to develop, or -1 when all are developed.
int firstUndevelopedIndex(List<Exposure> exposures, Set<String> developed) =>
    exposures.indexWhere((e) => !developed.contains(e.id));

/// Width of the strip for a screen [screenWidth] wide — the same size as the
/// negatives viewer, so the roll looks the same in both places.
double revealStripWidth(double screenWidth) => min(screenWidth * 0.72, 380.0);

/// A developing roll as the strip of film it is: scroll down the negatives,
/// tap one to develop it. The frame flips over in place and stays a print, so
/// the roll fills up with pictures as you go, and a developed frame opens
/// large when tapped.
///
/// Plain values and callbacks — the screen decides what "developed" means
/// for storage and what opening a print shows — so it can be widget-tested.
class RevealFilmStrip extends StatefulWidget {
  const RevealFilmStrip({
    super.key,
    required this.exposures,
    required this.developed,
    required this.style,
    required this.effectFor,
    required this.onDeveloped,
    required this.onOpenPrint,
    required this.hint,
    required this.tapToDevelop,
    this.footer,
  });

  final List<Exposure> exposures;

  /// Ids of the frames already developed.
  final Set<String> developed;
  final FilmStripStyle style;

  /// The effect a frame shows once developed (film stock look, Shiny foil…).
  final FilmEffect? Function(Exposure exposure) effectFor;

  /// A frame has finished flipping over to its print.
  final ValueChanged<Exposure> onDeveloped;

  /// A developed frame was tapped.
  final ValueChanged<Exposure> onOpenPrint;

  /// Shown above the first frame.
  final String hint;

  /// Pulses on the next frame to develop.
  final String tapToDevelop;

  /// Shown after the last frame, e.g. the way on to the gallery.
  final Widget? footer;

  /// Height of the hint above the first frame, used to scroll to a frame.
  static const double headerExtent = 64;

  @override
  State<RevealFilmStrip> createState() => _RevealFilmStripState();
}

class _RevealFilmStripState extends State<RevealFilmStrip> {
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  /// Opens the strip at the first frame still to develop, so coming back to
  /// a half-developed roll doesn't mean scrolling past the finished part.
  ScrollController _controllerFor(double segmentExtent) {
    return _scroll ??= ScrollController(
      initialScrollOffset: max(
        0,
        firstUndevelopedIndex(widget.exposures, widget.developed) *
            segmentExtent,
      ).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final segment = filmSegmentSize(
      revealStripWidth(width) / kFilmWidthMm,
      Axis.vertical,
    );
    final cacheWidth =
        (segment.width * MediaQuery.devicePixelRatioOf(context)).round();
    final next = firstUndevelopedIndex(widget.exposures, widget.developed);
    final outline = Theme.of(context).colorScheme.outline;

    return ListView.builder(
      controller: _controllerFor(segment.height),
      padding: const EdgeInsets.only(bottom: 48),
      itemCount: widget.exposures.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) {
          return SizedBox(
            height: RevealFilmStrip.headerExtent,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: outline, fontSize: 12),
                ),
              ),
            ),
          );
        }
        if (i == widget.exposures.length + 1) {
          return widget.footer ?? const SizedBox.shrink();
        }
        final index = i - 1;
        final exposure = widget.exposures[index];
        final isDeveloped = widget.developed.contains(exposure.id);
        return Center(
          child: SizedBox.fromSize(
            size: segment,
            child: _RevealSegment(
              key: ValueKey(exposure.id),
              index: index,
              exposure: exposure,
              style: widget.style,
              cacheWidth: cacheWidth,
              developed: isDeveloped,
              effect: widget.effectFor(exposure),
              showTapHint: index == next,
              tapToDevelop: widget.tapToDevelop,
              onDeveloped: () => widget.onDeveloped(exposure),
              onOpenPrint: () => widget.onOpenPrint(exposure),
            ),
          ),
        );
      },
    );
  }
}

class _RevealSegment extends StatefulWidget {
  const _RevealSegment({
    super.key,
    required this.index,
    required this.exposure,
    required this.style,
    required this.cacheWidth,
    required this.developed,
    required this.effect,
    required this.showTapHint,
    required this.tapToDevelop,
    required this.onDeveloped,
    required this.onOpenPrint,
  });

  final int index;
  final Exposure exposure;
  final FilmStripStyle style;
  final int cacheWidth;
  final bool developed;
  final FilmEffect? effect;
  final bool showTapHint;
  final String tapToDevelop;
  final VoidCallback onDeveloped;
  final VoidCallback onOpenPrint;

  @override
  State<_RevealSegment> createState() => _RevealSegmentState();
}

class _RevealSegmentState extends State<_RevealSegment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: widget.developed ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    _flip.addStatusListener((status) {
      if (status == AnimationStatus.completed && !widget.developed) {
        widget.onDeveloped();
      }
    });
  }

  @override
  void didUpdateWidget(_RevealSegment old) {
    super.didUpdateWidget(old);
    // "Skip all" develops every frame at once: show them as prints.
    if (widget.developed && _flip.value < 1 && !_flip.isAnimating) {
      _flip.value = 1;
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.developed || _flip.value >= 1) {
      widget.onOpenPrint();
    } else if (!_flip.isAnimating) {
      _flip.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: DecodedImageBuilder(
        path: widget.exposure.imagePath,
        cacheWidth: widget.cacheWidth,
        builder: (context, image) => AnimatedBuilder(
          animation: _flip,
          builder: (context, _) {
            final t = _flip.value;
            final showingPrint = t >= 0.5;
            return Stack(
              fit: StackFit.expand,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(showingPrint ? (t - 1) * pi : t * pi),
                  child: _painted(image, developed: showingPrint),
                ),
                if (widget.showTapHint && t == 0)
                  Align(
                    alignment: Alignment.center,
                    child: _PulsingLabel(text: widget.tapToDevelop),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _painted(ui.Image? image, {required bool developed}) {
    // Only a developed Shiny frame reacts to the phone tilting.
    final shiny = developed && (widget.effect?.isRare ?? false);
    return RepaintBoundary(
      child: CustomPaint(
        key: ValueKey('${widget.exposure.id}-${developed ? 'print' : 'neg'}'),
        size: Size.infinite,
        painter: _SegmentPainter(
          index: widget.index,
          style: widget.style,
          image: image,
          effect: developed ? widget.effect : null,
          developed: developed,
          tilt: shiny ? FoilTilt.instance : null,
        ),
      ),
    );
  }
}

class _SegmentPainter extends CustomPainter {
  _SegmentPainter({
    required this.index,
    required this.style,
    required this.image,
    required this.effect,
    required this.developed,
    required this.tilt,
  }) : super(repaint: tilt);

  final int index;
  final FilmStripStyle style;
  final ui.Image? image;
  final FilmEffect? effect;
  final bool developed;
  final ValueListenable<Offset>? tilt;

  @override
  void paint(Canvas canvas, Size size) {
    paintFilmSegment(
      canvas,
      Offset.zero & size,
      axis: Axis.vertical,
      index: index,
      style: style,
      image: image,
      effect: effect,
      developed: developed,
      tilt: tilt?.value ?? Offset.zero,
    );
  }

  @override
  bool shouldRepaint(_SegmentPainter old) =>
      old.index != index ||
      old.image != image ||
      old.effect?.serialized != effect?.serialized ||
      old.developed != developed ||
      old.style != style ||
      old.tilt != tilt;
}

class _PulsingLabel extends StatefulWidget {
  const _PulsingLabel({required this.text});

  final String text;

  @override
  State<_PulsingLabel> createState() => _PulsingLabelState();
}

class _PulsingLabelState extends State<_PulsingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 13,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
