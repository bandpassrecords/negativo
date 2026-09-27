import 'dart:math';
import 'package:flutter/material.dart';
import '../models/exposure.dart';
import '../models/film_roll.dart';
import 'foil.dart';

enum FilmEffectType {
  lightLeak,
  coldShift,
  heavyVignette,
  scratch,
  blownHighlights,
  shiny, // 1/150 per photo
}

class FilmEffect {
  final FilmEffectType type;
  final int variant;

  const FilmEffect({required this.type, required this.variant});

  // ── Probabilities ─────────────────────────────────────────────────────────

  /// Per-photo odds of a Shiny (foil) frame: 1 in [shinyOdds].
  static const shinyOdds = 150;

  // Per-roll: ~1 in 10 rolls gets one of the 5 degradation effects (equal chance).
  // Shiny is excluded — it is photo-specific and rolled separately.
  static FilmEffect? roll() {
    final rng = Random();
    if (rng.nextInt(10) != 0) return null;
    const degradation = [
      FilmEffectType.lightLeak,
      FilmEffectType.coldShift,
      FilmEffectType.heavyVignette,
      FilmEffectType.scratch,
      FilmEffectType.blownHighlights,
    ];
    final type = degradation[rng.nextInt(degradation.length)];
    return FilmEffect(type: type, variant: rng.nextInt(20));
  }

  // Per-photo: 1/[shinyOdds] chance of Shiny, rolled individually at reveal time.
  static FilmEffect? rollPhotoShiny() {
    final rng = Random();
    if (rng.nextInt(shinyOdds) != 0) return null;
    return FilmEffect(type: FilmEffectType.shiny, variant: rng.nextInt(20));
  }

  /// The effect shown on [exposure]: its own Shiny foil wins, otherwise the
  /// roll's effect — each only if the user hasn't turned it off. The foil can
  /// be turned off for the whole album or for this one photo.
  static FilmEffect? forExposure(Exposure exposure, FilmRoll roll) {
    final own = fromString(exposure.filmEffect);
    if (own != null && (!own.isRare || hasFoilShown(exposure, roll))) {
      return own;
    }
    return roll.effectEnabled ? fromString(roll.filmEffect) : null;
  }

  /// Whether [exposure] has a Shiny foil at all, switched on or not — what
  /// decides if a per-photo foil switch is worth offering.
  static bool hasFoil(Exposure exposure) =>
      fromString(exposure.filmEffect)?.isRare ?? false;

  /// Whether [exposure]'s foil is showing: it has one, and neither the album
  /// nor the photo has it switched off.
  static bool hasFoilShown(Exposure exposure, FilmRoll roll) =>
      hasFoil(exposure) && roll.foilEnabled && exposure.foilEnabled;

  String get serialized => '${type.name}:$variant';

  static FilmEffect? fromString(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    try {
      final t = FilmEffectType.values.byName(parts[0]);
      final v = int.parse(parts[1]);
      return FilmEffect(type: t, variant: v);
    } catch (_) {
      return null;
    }
  }

  bool get isRare => type == FilmEffectType.shiny;

  String get displayName => switch (type) {
        FilmEffectType.lightLeak => 'Light Leak',
        FilmEffectType.coldShift => 'Cold Shift',
        FilmEffectType.heavyVignette => 'Heavy Vignette',
        FilmEffectType.scratch => 'Film Scratch',
        FilmEffectType.blownHighlights => 'Blown Highlights',
        FilmEffectType.shiny => 'Shiny ✨',
      };

  // ── Rendering ─────────────────────────────────────────────────────────────

  /// Paints this effect over a photo already drawn into [rect] on [canvas].
  ///
  /// All sizes are relative to [rect], so the same call renders the on-screen
  /// preview, a film-strip frame and the full-resolution exported JPEG.
  /// [tilt] (each axis −1…1) only affects the Shiny foil. The foil blends with
  /// the pixels underneath, so paint it into the same layer as the photo.
  void paint(Canvas canvas, Rect rect, {Offset tilt = Offset.zero}) {
    switch (type) {
      case FilmEffectType.lightLeak:
        const corners = [
          Alignment.topLeft,
          Alignment.topRight,
          Alignment.bottomLeft,
          Alignment.bottomRight,
        ];
        canvas.drawRect(
          rect,
          Paint()
            ..shader = RadialGradient(
              center: corners[variant % 4],
              radius: 1.4,
              colors: const [
                Color(0x99FF7500),
                Color(0x66FF3300),
                Color(0x33FF0080),
                Colors.transparent,
              ],
              stops: const [0.0, 0.25, 0.55, 0.85],
            ).createShader(rect),
        );
      case FilmEffectType.coldShift:
        const colors = [
          Color(0x330044FF),
          Color(0x2800C8C0),
          Color(0x308800CC),
        ];
        canvas.drawRect(rect, Paint()..color = colors[variant % 3]);
      case FilmEffectType.heavyVignette:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = const RadialGradient(
              radius: 1.1,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Color(0x88000000),
                Color(0xCC000000),
              ],
              stops: [0.0, 0.45, 0.75, 1.0],
            ).createShader(rect),
        );
      case FilmEffectType.scratch:
        final rng = Random(variant);
        final count = 1 + (variant % 3);
        for (int i = 0; i < count; i++) {
          final x = rect.left + rect.width * (0.1 + rng.nextDouble() * 0.8);
          final wobble = rect.width * (rng.nextDouble() * 0.015 - 0.0075);
          final paint = Paint()
            ..color =
                Colors.white.withValues(alpha: 0.25 + rng.nextDouble() * 0.35)
            ..strokeWidth = rect.width * (0.001 + rng.nextDouble() * 0.002)
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(x, rect.top),
            Offset(x + wobble, rect.bottom),
            paint,
          );
        }
      case FilmEffectType.blownHighlights:
        const pairs = [
          [Alignment.topLeft, Alignment.bottomRight],
          [Alignment.topRight, Alignment.bottomLeft],
          [Alignment.bottomLeft, Alignment.topRight],
          [Alignment.bottomRight, Alignment.topLeft],
        ];
        final pair = pairs[variant % 4];
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: pair[0],
              end: pair[1],
              colors: const [
                Color(0x88FFFFFF),
                Color(0x33FFFFFF),
                Colors.transparent,
              ],
              stops: const [0.0, 0.22, 0.55],
            ).createShader(rect),
        );
      case FilmEffectType.shiny:
        paintFoil(canvas, rect, variant: variant, tilt: tilt);
    }
  }

  // Cheap static overlay for small grid tiles (no blending, no motion).
  Widget buildTileOverlay() {
    if (type == FilmEffectType.shiny) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0x55FF0000),
              Color(0x55FF7F00),
              Color(0x55FFFF00),
              Color(0x5500FF88),
              Color(0x550088FF),
              Color(0x558800FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: _EffectOverlayPainter(this),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _EffectOverlayPainter extends CustomPainter {
  final FilmEffect effect;
  const _EffectOverlayPainter(this.effect);

  @override
  void paint(Canvas canvas, Size size) =>
      effect.paint(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(_EffectOverlayPainter old) =>
      old.effect.serialized != effect.serialized;
}
