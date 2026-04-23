import 'dart:math';
import 'package:flutter/material.dart';

enum FilmEffectType {
  lightLeak,
  coldShift,
  heavyVignette,
  scratch,
  blownHighlights,
  shiny, // 1/8000
}

class FilmEffect {
  final FilmEffectType type;
  final int variant;

  const FilmEffect({required this.type, required this.variant});

  // ── Probabilities ─────────────────────────────────────────────────────────

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

  // Per-photo: 1/8000 chance of Shiny, rolled individually at reveal time.
  static FilmEffect? rollPhotoShiny() {
    final rng = Random();
    if (rng.nextInt(8000) != 0) return null;
    return FilmEffect(type: FilmEffectType.shiny, variant: rng.nextInt(20));
  }

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

  // For shiny, the image itself must be wrapped with ShaderMask.
  // For all others, this is a no-op passthrough.
  Widget wrapImage(Widget imageWidget) {
    if (type != FilmEffectType.shiny) return imageWidget;
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFF7F00),
          Color(0xFFFFFF00),
          Color(0xFF00FF88),
          Color(0xFF0088FF),
          Color(0xFF8800FF),
          Color(0xFFFF0088),
          Color(0xFFFF0000),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      blendMode: BlendMode.color,
      child: imageWidget,
    );
  }

  // Overlay widget drawn on top of the (possibly wrapped) image.
  Widget buildOverlay() => switch (type) {
    FilmEffectType.lightLeak => _LightLeakOverlay(variant: variant),
    FilmEffectType.coldShift => _ColdShiftOverlay(variant: variant),
    FilmEffectType.heavyVignette => const _HeavyVignetteOverlay(),
    FilmEffectType.scratch => _ScratchOverlay(variant: variant),
    FilmEffectType.blownHighlights => _BlownHighlightsOverlay(variant: variant),
    FilmEffectType.shiny => _ShinySparkleOverlay(variant: variant),
  };

  // Simpler overlay for small grid tiles (no ShaderMask for performance).
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
    return buildOverlay();
  }
}

// ─── Effect overlays ──────────────────────────────────────────────────────────

class _LightLeakOverlay extends StatelessWidget {
  final int variant;
  const _LightLeakOverlay({required this.variant});

  static const _corners = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: _corners[variant % 4],
            radius: 1.4,
            colors: const [
              Color(0x99FF7500),
              Color(0x66FF3300),
              Color(0x33FF0080),
              Colors.transparent,
            ],
            stops: const [0.0, 0.25, 0.55, 0.85],
          ),
        ),
      ),
    );
  }
}

class _ColdShiftOverlay extends StatelessWidget {
  final int variant;
  const _ColdShiftOverlay({required this.variant});

  static const _colors = [
    Color(0x330044FF),
    Color(0x2800C8C0),
    Color(0x308800CC),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(color: _colors[variant % 3]),
    );
  }
}

class _HeavyVignetteOverlay extends StatelessWidget {
  const _HeavyVignetteOverlay();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Color(0x88000000),
              Color(0xCC000000),
            ],
            stops: [0.0, 0.45, 0.75, 1.0],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _ScratchOverlay extends StatelessWidget {
  final int variant;
  const _ScratchOverlay({required this.variant});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _ScratchPainter(variant)),
    );
  }
}

class _ScratchPainter extends CustomPainter {
  final int variant;
  const _ScratchPainter(this.variant);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(variant);
    final count = 1 + (variant % 3);
    for (int i = 0; i < count; i++) {
      final x = size.width * (0.1 + rng.nextDouble() * 0.8);
      final wobble = rng.nextDouble() * 6 - 3;
      final paint = Paint()
        ..color = Colors.white.withValues(
            alpha: 0.25 + rng.nextDouble() * 0.35)
        ..strokeWidth = 0.4 + rng.nextDouble() * 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x, 0), Offset(x + wobble, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_ScratchPainter old) => old.variant != variant;
}

class _BlownHighlightsOverlay extends StatelessWidget {
  final int variant;
  const _BlownHighlightsOverlay({required this.variant});

  static const _pairs = [
    [Alignment.topLeft, Alignment.bottomRight],
    [Alignment.topRight, Alignment.bottomLeft],
    [Alignment.bottomLeft, Alignment.topRight],
    [Alignment.bottomRight, Alignment.topLeft],
  ];

  @override
  Widget build(BuildContext context) {
    final pair = _pairs[variant % 4];
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: pair[0],
            end: pair[1],
            colors: const [
              Color(0x88FFFFFF),
              Color(0x33FFFFFF),
              Colors.transparent,
            ],
            stops: const [0.0, 0.22, 0.55],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ShinySparkleOverlay extends StatelessWidget {
  final int variant;
  const _ShinySparkleOverlay({required this.variant});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _SparklePainter(variant)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final int variant;
  const _SparklePainter(this.variant);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(variant + 1337);
    for (int i = 0; i < 12; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 1.5 + rng.nextDouble() * 3.5;
      final alpha = 0.5 + rng.nextDouble() * 0.5;
      final hue = rng.nextDouble() * 360;

      final glow = Paint()
        ..color = HSLColor.fromAHSL(alpha * 0.4, hue, 1.0, 0.8).toColor()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, y), r * 2, glow);

      final core = Paint()
        ..color = HSLColor.fromAHSL(alpha, hue, 1.0, 0.95).toColor();
      canvas.drawCircle(Offset(x, y), r, core);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.variant != variant;
}
