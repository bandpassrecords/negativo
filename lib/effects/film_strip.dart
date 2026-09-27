import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/film_stock.dart';
import 'effect_photo.dart';
import 'film_effect.dart';

// Real 35 mm geometry, in millimetres.
const kFilmWidthMm = 35.0;
const kFramePitchMm = 38.0; // 36 mm frame + 2 mm gap
const _frameAlongMm = 36.0;
const _frameAcrossMm = 24.0;
const _borderMm = (kFilmWidthMm - _frameAcrossMm) / 2;
const _perfPitchMm = kFramePitchMm / 8;
const _perfAlongMm = 1.98;
const _perfAcrossMm = 2.2;
const _perfOffsetMm = 2.9; // film edge → perforation centre
const _edgeTextMm = 1.25;

/// The light shining through a light table.
const kLightTableColor = Color(0xFFFFFCF5);

class FilmStripStyle {
  final Color base;
  final Color edgeInk;
  final String edgeText;

  const FilmStripStyle({
    required this.base,
    required this.edgeInk,
    required this.edgeText,
  });

  factory FilmStripStyle.forStock(String? filmStockId) {
    final stock = FilmStock.fromId(filmStockId);
    final base = negativeBaseFor(filmStockId);
    return FilmStripStyle(
      base: base,
      // Edge printing is exposed at the factory, so it is dense on the negative.
      edgeInk: Color.lerp(base, Colors.black, 0.72)!,
      edgeText: stock == null
          ? 'NEGATIVO'
          : '${stock.brand} ${stock.name}'.toUpperCase(),
    );
  }
}

/// Size of one frame's stretch of film at [pxPerMm].
Size filmSegmentSize(double pxPerMm, Axis axis) => axis == Axis.horizontal
    ? Size(kFramePitchMm * pxPerMm, kFilmWidthMm * pxPerMm)
    : Size(kFilmWidthMm * pxPerMm, kFramePitchMm * pxPerMm);

/// Where the picture sits inside a [segment] of film.
Rect filmFrameRect(Rect segment, Axis axis) {
  final s =
      (axis == Axis.horizontal ? segment.height : segment.width) / kFilmWidthMm;
  const along = (kFramePitchMm - _frameAlongMm) / 2;
  return axis == Axis.horizontal
      ? Rect.fromLTWH(segment.left + along * s, segment.top + _borderMm * s,
          _frameAlongMm * s, _frameAcrossMm * s)
      : Rect.fromLTWH(segment.left + _borderMm * s, segment.top + along * s,
          _frameAcrossMm * s, _frameAlongMm * s);
}

/// Paints frame [index] (0-based) of a developed roll as a stretch of
/// negative film lying on a light table: film base, perforations, edge
/// printing and the inverted picture with its effect.
///
/// With [developed] the picture is drawn as the print instead of the
/// negative — the reveal flips each frame over to this as it is developed,
/// so the roll fills up with prints as you work down it.
void paintFilmSegment(
  Canvas canvas,
  Rect segment, {
  required Axis axis,
  required int index,
  required FilmStripStyle style,
  ui.Image? image,
  FilmEffect? effect,
  Offset tilt = Offset.zero,
  bool developed = false,
}) {
  final s =
      (axis == Axis.horizontal ? segment.height : segment.width) / kFilmWidthMm;

  // Work in (along, across) film coordinates; a vertical strip is the same
  // film turned 90° clockwise, so the edge printing reads top to bottom.
  canvas.save();
  if (axis == Axis.horizontal) {
    canvas.translate(segment.left, segment.top);
  } else {
    canvas.translate(segment.right, segment.top);
    canvas.rotate(pi / 2);
  }
  canvas.scale(s);

  canvas.drawRect(const Rect.fromLTWH(0, 0, kFramePitchMm, kFilmWidthMm),
      Paint()..color = style.base);

  final hole = Paint()..color = kLightTableColor;
  for (var k = 0; k < 8; k++) {
    final along = (k + 0.5) * _perfPitchMm;
    for (final across in const [_perfOffsetMm, kFilmWidthMm - _perfOffsetMm]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(along, across),
            width: _perfAlongMm,
            height: _perfAcrossMm,
          ),
          const Radius.circular(0.45),
        ),
        hole,
      );
    }
  }

  final number = index + 1;
  // Brand along the top edge on every other frame, frame numbers along the
  // bottom edge: "12" under the picture, "▸12A" between pictures.
  if (index.isEven) {
    _edgeText(canvas, style.edgeText, style.edgeInk, const Offset(3, 0.15));
  }
  const bottom = kFilmWidthMm - _edgeTextMm - 0.25;
  _edgeText(canvas, '$number', style.edgeInk,
      const Offset(kFramePitchMm / 2 - 1, bottom));
  _edgeText(canvas, '▸${number}A', style.edgeInk,
      const Offset(kFramePitchMm - 3.5, bottom));

  canvas.restore();

  final frame = filmFrameRect(segment, axis);
  if (image != null) {
    paintEffectPhoto(
      canvas,
      frame,
      image,
      effect: effect,
      negative: !developed,
      negativeBase: style.base,
      rotateToFit: true,
      tilt: tilt,
    );
  }
}

void _edgeText(Canvas canvas, String text, Color color, Offset at) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: _edgeTextMm,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.12,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, at);
  painter.dispose();
}
