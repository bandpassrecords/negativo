import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../effects/effect_photo.dart';
import '../effects/film_effect.dart';
import '../effects/film_strip.dart';
import '../effects/foil.dart';
import '../models/exposure.dart';
import '../models/film_roll.dart';
import '../models/film_stock.dart';

/// Produces the files that leave the app: photos with their film effect baked
/// in, and contact sheets of a roll's negatives.
class ExportService {
  ExportService._();

  /// Path of [exposure] as it should be shared: the original file when it has
  /// no effect, otherwise a cached JPEG with the effect (and foil) drawn in.
  static Future<String> photoPath(Exposure exposure, FilmRoll roll) async {
    final effect = FilmEffect.forExposure(exposure, roll);
    final source = File(exposure.imagePath);
    if (effect == null || !source.existsSync()) return exposure.imagePath;

    final dir = await _exportDir();
    final out = File(p.join(
      dir.path,
      '${exposure.id}_${effect.serialized.replaceAll(':', '-')}.jpg',
    ));
    if (out.existsSync() &&
        out.lastModifiedSync().isAfter(source.lastModifiedSync())) {
      return out.path;
    }

    final image = await _decode(source);
    try {
      final size = Size(image.width.toDouble(), image.height.toDouble());
      final baked = await _render(size, (canvas) {
        paintEffectPhoto(
          canvas,
          Offset.zero & size,
          image,
          effect: effect,
          fit: BoxFit.fill,
          tilt: kStillFoilTilt,
        );
      });
      await out.writeAsBytes(await _encodeJpg(baked));
      baked.dispose();
    } finally {
      image.dispose();
    }
    return out.path;
  }

  static Future<List<String>> photoPaths(
    Iterable<Exposure> exposures,
    FilmRoll roll,
  ) =>
      Future.wait(exposures.map((e) => photoPath(e, roll)));

  /// Renders the roll's negatives, cut into strips of six like a negative
  /// sleeve, on a light table. [countLabel] is the localized photo count
  /// shown in the header. Returns the JPEG's path.
  static Future<String> contactSheet(
    FilmRoll roll,
    List<Exposure> exposures, {
    required String countLabel,
  }) async {
    const pxPerMm = 12.0;
    const perStrip = 6;
    const margin = 72.0;
    const headerHeight = 150.0;
    const stripGap = 44.0;

    final style = FilmStripStyle.forStock(roll.filmStockId);
    final segment = filmSegmentSize(pxPerMm, Axis.horizontal);
    final strips = max(1, (exposures.length / perStrip).ceil());
    final size = Size(
      margin * 2 + segment.width * perStrip,
      margin * 2 +
          headerHeight +
          strips * segment.height +
          (strips - 1) * stripGap,
    );

    final images = await Future.wait(exposures.map((e) async {
      final file = File(e.imagePath);
      return file.existsSync() ? _decode(file, targetWidth: 640) : null;
    }));

    try {
      final sheet = await _render(size, (canvas) {
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = const RadialGradient(
              radius: 0.9,
              colors: [kLightTableColor, Color(0xFFF1EBDD)],
            ).createShader(Offset.zero & size),
        );
        _paintHeader(
            canvas,
            roll,
            countLabel,
            Rect.fromLTWH(
                margin, margin, size.width - margin * 2, headerHeight));

        for (var i = 0; i < exposures.length; i++) {
          final row = i ~/ perStrip;
          final col = i % perStrip;
          final origin = Offset(
            margin + col * segment.width,
            margin + headerHeight + row * (segment.height + stripGap),
          );
          paintFilmSegment(
            canvas,
            origin & segment,
            axis: Axis.horizontal,
            index: i,
            style: style,
            image: images[i],
            effect: FilmEffect.forExposure(exposures[i], roll),
            tilt: kStillFoilTilt,
          );
        }
      });

      final dir = await _exportDir();
      final safeName = roll.name.replaceAll(RegExp(r'[^\w\- ]'), '').trim();
      final out = File(p.join(
        dir.path,
        'Negativo - ${safeName.isEmpty ? roll.id : safeName} - negatives.jpg',
      ));
      await out.writeAsBytes(await _encodeJpg(sheet));
      sheet.dispose();
      return out.path;
    } finally {
      for (final image in images) {
        image?.dispose();
      }
    }
  }

  static void _paintHeader(
      Canvas canvas, FilmRoll roll, String countLabel, Rect rect) {
    final stock = FilmStock.fromId(roll.filmStockId);
    final date = DateFormat.yMMMd()
        .format((roll.developmentStartedAt ?? roll.createdAt).toLocal());
    final subtitle = [
      if (stock != null) '${stock.brand} ${stock.name}',
      countLabel,
      date,
    ].join('  ·  ');

    final title = TextPainter(
      text: TextSpan(
        text: roll.name,
        style: const TextStyle(
          color: Color(0xFF2B2118),
          fontSize: 64,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: rect.width);
    title.paint(canvas, rect.topLeft);

    final sub = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: const TextStyle(
          color: Color(0xFF7A6A58),
          fontSize: 30,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: rect.width);
    sub.paint(canvas, rect.topLeft + Offset(0, title.height + 10));
    title.dispose();
    sub.dispose();
  }

  static Future<Directory> _exportDir() async {
    final dir =
        Directory(p.join((await getTemporaryDirectory()).path, 'export'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  static Future<ui.Image> _decode(File file, {int? targetWidth}) async {
    final codec = await ui.instantiateImageCodec(
      await file.readAsBytes(),
      targetWidth: targetWidth,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static Future<ui.Image> _render(Size size, void Function(Canvas) paint) {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder));
    final picture = recorder.endRecording();
    return picture
        .toImage(size.width.round(), size.height.round())
        .whenComplete(picture.dispose);
  }

  static Future<Uint8List> _encodeJpg(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return compute(_encodeJpgIsolate, (
      bytes: data!.buffer.asUint8List(),
      width: image.width,
      height: image.height,
    ));
  }
}

Uint8List _encodeJpgIsolate(({Uint8List bytes, int width, int height}) raw) {
  final image = img.Image.fromBytes(
    width: raw.width,
    height: raw.height,
    bytes: raw.bytes.buffer,
    numChannels: 4,
  );
  return img.encodeJpg(image, quality: 92);
}
