import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Tilt used when there is no phone to tilt — exported JPEGs and contact sheets.
const kStillFoilTilt = Offset(0.35, -0.25);

const _rainbow = [
  Color(0xFFFF0040),
  Color(0xFFFF9900),
  Color(0xFFFFF200),
  Color(0xFF00FF88),
  Color(0xFF00B7FF),
  Color(0xFF7A00FF),
  Color(0xFFFF00C8),
  Color(0xFFFF0040),
];

/// Paints a holographic foil over whatever is already in [rect].
///
/// Everything moves with [tilt] (each axis −1…1) the way a foil trading card
/// catches the light: the rainbow slides, the diffraction lines shift faster,
/// the glare follows the light and the sparkles twinkle.
void paintFoil(
  Canvas canvas,
  Rect rect, {
  required int variant,
  Offset tilt = Offset.zero,
}) {
  final rng = Random(variant + 1337);
  final shortest = rect.shortestSide;
  final angle = pi / 4 + (rng.nextDouble() - 0.5) * pi / 3;
  final dir = Offset(cos(angle), sin(angle));
  final phase = tilt.dx * 0.9 + tilt.dy * 0.6;

  canvas.save();
  canvas.clipRect(rect);

  // 1. Rainbow hue sweep, keeping the photo's luminosity.
  final bandLength = rect.longestSide * 0.9;
  final start =
      rect.center - dir * (bandLength / 2) + dir * (phase * bandLength);
  canvas.drawRect(
    rect,
    Paint()
      ..blendMode = BlendMode.color
      ..color = const Color(0x80000000) // 50% strength
      ..shader = LinearGradient(
        colors: _rainbow,
        tileMode: TileMode.mirror,
      ).createShader(Rect.fromPoints(start, start + dir * bandLength)),
  );

  // 2. Fine diffraction lines, perpendicular to the sweep and moving faster.
  final lineDir = Offset(-dir.dy, dir.dx);
  final period = shortest * 0.09;
  final lineStart = rect.center + lineDir * (phase * period * 6);
  canvas.drawRect(
    rect,
    Paint()
      ..blendMode = BlendMode.softLight
      ..shader = LinearGradient(
        colors: const [
          Color(0x00FFFFFF),
          Color(0x40FFFFFF),
          Color(0x00FFFFFF),
          Color(0x22000000),
          Color(0x00FFFFFF),
        ],
        tileMode: TileMode.repeated,
      ).createShader(Rect.fromPoints(lineStart, lineStart + lineDir * period)),
  );

  // 3. Glare where the light source hits.
  final glareCenter = Alignment(
    (-tilt.dx * 0.9).clamp(-1.0, 1.0),
    (-tilt.dy * 0.9).clamp(-1.0, 1.0),
  );
  canvas.drawRect(
    rect,
    Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        center: glareCenter,
        radius: 0.75,
        colors: const [Color(0x73FFFFFF), Color(0x1FFFFFFF), Color(0x00FFFFFF)],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(rect),
  );

  // 4. Sparkles that twinkle as the card moves.
  for (int i = 0; i < 12; i++) {
    final p = Offset(
      rect.left + rng.nextDouble() * rect.width,
      rect.top + rng.nextDouble() * rect.height,
    );
    final r = shortest * (0.004 + rng.nextDouble() * 0.009);
    final hue = rng.nextDouble() * 360;
    final twinkle =
        0.5 + 0.5 * sin(rng.nextDouble() * 2 * pi + tilt.dx * 4 - tilt.dy * 3);
    final alpha = (0.5 + rng.nextDouble() * 0.5) * (0.25 + 0.75 * twinkle);

    canvas.drawCircle(
      p,
      r * 2,
      Paint()
        ..color = HSLColor.fromAHSL(alpha * 0.4, hue, 1.0, 0.8).toColor()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shortest * 0.015),
    );
    canvas.drawCircle(
      p,
      r,
      Paint()..color = HSLColor.fromAHSL(alpha, hue, 1.0, 0.95).toColor(),
    );
  }

  canvas.restore();
}

/// Phone tilt from the accelerometer, smoothed, each axis −1…1.
///
/// Shared by every foil on screen. The sensor only runs while something is
/// listening.
class FoilTilt extends ChangeNotifier implements ValueListenable<Offset> {
  FoilTilt._();

  static final FoilTilt instance = FoilTilt._();

  StreamSubscription<AccelerometerEvent>? _sub;
  Offset _value = Offset.zero;

  @override
  Offset get value => _value;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _sub ??= accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onEvent, onError: (_) {}, cancelOnError: true);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _sub?.cancel();
      _sub = null;
    }
  }

  void _onEvent(AccelerometerEvent e) {
    // Left/right roll, and forward/back pitch around the ~45° reading angle.
    final target = Offset(
      (-e.x / 6).clamp(-1.0, 1.0),
      ((e.z - e.y) / 9.8).clamp(-1.0, 1.0),
    );
    final next = Offset.lerp(_value, target, 0.2)!;
    if ((next - _value).distance < 0.002) return;
    _value = next;
    notifyListeners();
  }
}
