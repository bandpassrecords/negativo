import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'film_effect.dart';
import 'foil.dart';

const _negativeMatrix = <double>[
  -1, 0, 0, 0, 255, //
  0, -1, 0, 0, 255, //
  0, 0, -1, 0, 255, //
  0, 0, 0, 1, 0, //
];

/// Colour of the developed film base, multiplied over the inverted image.
/// Colour negative film has an orange mask; B&W and Cinestill (no remjet
/// layer) are much closer to clear.
Color negativeBaseFor(String? filmStockId) => switch (filmStockId) {
      'hp5' => const Color(0xFFE6E4DE),
      'cinestill800t' => const Color(0xFFEBD2C2),
      _ => const Color(0xFFF2B27A),
    };

/// Paints [image] into [box] with its film [effect].
///
/// With [negative] the photo and its degradation effect are inverted and
/// tinted with [negativeBase], like the developed negative. The Shiny foil is
/// always painted on top, un-inverted. With [rotateToFit] a landscape photo in
/// a portrait box (or vice versa) is turned 90°, the way it sits on film.
void paintEffectPhoto(
  Canvas canvas,
  Rect box,
  ui.Image image, {
  FilmEffect? effect,
  BoxFit fit = BoxFit.cover,
  bool negative = false,
  Color negativeBase = const Color(0xFFF2B27A),
  bool rotateToFit = false,
  Offset tilt = Offset.zero,
}) {
  final imageSize = Size(image.width.toDouble(), image.height.toDouble());
  final rotate = rotateToFit &&
      (imageSize.width > imageSize.height) != (box.width > box.height);
  final photoBox = rotate ? Size(box.height, box.width) : box.size;
  final fitted = applyBoxFit(fit, imageSize, photoBox);
  final src = Alignment.center.inscribe(fitted.source, Offset.zero & imageSize);
  final dst =
      Alignment.center.inscribe(fitted.destination, Offset.zero & photoBox);

  canvas.save();
  canvas.clipRect(box);
  canvas.translate(box.center.dx, box.center.dy);
  if (rotate) canvas.rotate(pi / 2);
  canvas.translate(-photoBox.width / 2, -photoBox.height / 2);

  final isolate = effect?.isRare ?? false;
  if (isolate) canvas.saveLayer(dst, Paint());

  if (negative) {
    canvas.saveLayer(
        dst, Paint()..colorFilter = const ColorFilter.matrix(_negativeMatrix));
  }
  canvas.drawImageRect(
      image, src, dst, Paint()..filterQuality = FilterQuality.medium);
  if (effect != null && !effect.isRare) effect.paint(canvas, dst);
  if (negative) {
    canvas.restore();
    canvas.drawRect(
      dst,
      Paint()
        ..color = negativeBase
        ..blendMode = BlendMode.multiply,
    );
  }

  if (effect != null && effect.isRare) effect.paint(canvas, dst, tilt: tilt);
  if (isolate) canvas.restore();
  canvas.restore();
}

/// Decodes the image at [path] (optionally downscaled to [cacheWidth]) and
/// hands the [ui.Image] to [builder] — null while loading or if missing.
class DecodedImageBuilder extends StatefulWidget {
  final String path;
  final int? cacheWidth;
  final Widget Function(BuildContext context, ui.Image? image) builder;

  const DecodedImageBuilder({
    super.key,
    required this.path,
    this.cacheWidth,
    required this.builder,
  });

  @override
  State<DecodedImageBuilder> createState() => _DecodedImageBuilderState();
}

class _DecodedImageBuilderState extends State<DecodedImageBuilder> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _info;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(DecodedImageBuilder old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path || old.cacheWidth != widget.cacheWidth) {
      _resolve();
    }
  }

  void _resolve() {
    final file = File(widget.path);
    if (!file.existsSync()) {
      _stopListening();
      _setInfo(null);
      return;
    }
    ImageProvider<Object> provider = FileImage(file);
    if (widget.cacheWidth != null) {
      provider = ResizeImage(provider,
          width: widget.cacheWidth, policy: ResizeImagePolicy.fit);
    }
    final stream = provider.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stopListening();
    _stream = stream;
    _listener = ImageStreamListener(
      (info, _) => _setInfo(info),
      onError: (_, __) => _setInfo(null),
    );
    stream.addListener(_listener!);
  }

  void _setInfo(ImageInfo? info) {
    if (!mounted) return;
    setState(() {
      _info?.dispose();
      _info = info;
    });
  }

  void _stopListening() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _stopListening();
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _info?.image);
}

/// A photo with its film effect; Shiny frames shimmer as the phone tilts.
class EffectPhoto extends StatelessWidget {
  final String imagePath;
  final FilmEffect? effect;
  final BoxFit fit;
  final bool negative;
  final Color negativeBase;
  final bool rotateToFit;
  final int? cacheWidth;

  const EffectPhoto({
    super.key,
    required this.imagePath,
    this.effect,
    this.fit = BoxFit.contain,
    this.negative = false,
    this.negativeBase = const Color(0xFFF2B27A),
    this.rotateToFit = false,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    return DecodedImageBuilder(
      path: imagePath,
      cacheWidth: cacheWidth,
      builder: (context, image) => LayoutBuilder(
        builder: (context, constraints) {
          final bounded =
              constraints.hasBoundedWidth && constraints.hasBoundedHeight;
          if (image == null) {
            return bounded ? const SizedBox.expand() : const SizedBox.shrink();
          }
          final photo = _paint(image);
          // Unbounded (e.g. in a Column): size to the photo like Image does.
          return bounded
              ? photo
              : AspectRatio(
                  aspectRatio: image.width / image.height,
                  child: photo,
                );
        },
      ),
    );
  }

  Widget _paint(ui.Image image) {
    final shiny = effect?.isRare ?? false;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _EffectPhotoPainter(
          image: image,
          effect: effect,
          fit: fit,
          negative: negative,
          negativeBase: negativeBase,
          rotateToFit: rotateToFit,
          tilt: shiny ? FoilTilt.instance : null,
        ),
      ),
    );
  }
}

class _EffectPhotoPainter extends CustomPainter {
  final ui.Image image;
  final FilmEffect? effect;
  final BoxFit fit;
  final bool negative;
  final Color negativeBase;
  final bool rotateToFit;
  final ValueListenable<Offset>? tilt;

  _EffectPhotoPainter({
    required this.image,
    required this.effect,
    required this.fit,
    required this.negative,
    required this.negativeBase,
    required this.rotateToFit,
    required this.tilt,
  }) : super(repaint: tilt);

  @override
  void paint(Canvas canvas, Size size) {
    paintEffectPhoto(
      canvas,
      Offset.zero & size,
      image,
      effect: effect,
      fit: fit,
      negative: negative,
      negativeBase: negativeBase,
      rotateToFit: rotateToFit,
      tilt: tilt?.value ?? Offset.zero,
    );
  }

  @override
  bool shouldRepaint(_EffectPhotoPainter old) =>
      old.image != image ||
      old.effect?.serialized != effect?.serialized ||
      old.fit != fit ||
      old.negative != negative ||
      old.negativeBase != negativeBase ||
      old.rotateToFit != rotateToFit ||
      old.tilt != tilt;
}
