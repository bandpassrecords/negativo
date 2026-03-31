import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class FilmStockService {
  /// Applies the film stock filter to an already-saved JPEG file in-place.
  /// Runs in a background isolate so the UI stays responsive.
  static Future<void> applyToFile(String filePath, String stockId) async {
    await compute(_processImage, {'path': filePath, 'stockId': stockId});
  }
}

// ─── Isolate entry point (must be top-level) ─────────────────────────────────

Future<void> _processImage(Map<String, String> args) async {
  final path    = args['path']!;
  final stockId = args['stockId']!;

  final bytes    = await File(path).readAsBytes();
  final original = img.decodeImage(bytes);
  if (original == null) return;

  final processed = _applyStock(original, stockId);
  final encoded   = img.encodeJpg(processed, quality: 92);
  await File(path).writeAsBytes(encoded);
}

img.Image _applyStock(img.Image src, String stockId) {
  switch (stockId) {
    case 'portra400':    return _portra400(src);
    case 'velvia50':     return _velvia50(src);
    case 'hp5':          return _hp5(src);
    case 'ektar100':     return _ektar100(src);
    case 'cinestill800t': return _cinestill800t(src);
    default:             return src; // gold200 and any unknown = no filter
  }
}

// ─── Kodak Portra 400 ────────────────────────────────────────────────────────
// Warm amber cast, lifted shadows, slight desaturation.
img.Image _portra400(img.Image src) {
  final out = src.clone();
  for (final pixel in out) {
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();
    pixel.r = _c(r * 1.10 + 10);
    pixel.g = _c(g * 1.03 + 8);
    pixel.b = _c(b * 0.88 + 12);
  }
  return img.adjustColor(out, saturation: 0.85, contrast: 0.92);
}

// ─── Fujifilm Velvia 50 ──────────────────────────────────────────────────────
// Hyper-saturated, punchy contrast, cool blue-green cast.
img.Image _velvia50(img.Image src) {
  final out = src.clone();
  for (final pixel in out) {
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();
    pixel.r = _c(r * 0.96);
    pixel.g = _c(g * 1.06);
    pixel.b = _c(b * 1.10);
  }
  return img.adjustColor(out, saturation: 1.55, contrast: 1.22);
}

// ─── Ilford HP5 Plus ─────────────────────────────────────────────────────────
// Classic black-and-white with rich contrast.
img.Image _hp5(img.Image src) {
  final bw = img.grayscale(src);
  return img.adjustColor(bw, contrast: 1.15);
}

// ─── Kodak Ektar 100 ─────────────────────────────────────────────────────────
// Ultra-vivid, punchy reds, high saturation.
img.Image _ektar100(img.Image src) {
  final out = src.clone();
  for (final pixel in out) {
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();
    pixel.r = _c(r * 1.14);
    pixel.g = _c(g * 0.97);
    pixel.b = _c(b * 1.03);
  }
  return img.adjustColor(out, saturation: 1.35, contrast: 1.18);
}

// ─── Cinestill 800T ──────────────────────────────────────────────────────────
// Tungsten-balanced: cool blue cast, lifted blacks, slight desaturation.
img.Image _cinestill800t(img.Image src) {
  final out = src.clone();
  for (final pixel in out) {
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();
    pixel.r = _c(r * 0.94 + 8);
    pixel.g = _c(g * 0.97 + 6);
    pixel.b = _c(b * 1.10 + 10);
  }
  return img.adjustColor(out, saturation: 0.88, contrast: 1.06);
}

int _c(double v) => v.clamp(0.0, 255.0).round();
