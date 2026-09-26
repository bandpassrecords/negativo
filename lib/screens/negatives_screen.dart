import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../effects/effect_photo.dart';
import '../effects/film_effect.dart';
import '../effects/film_strip.dart';
import '../effects/foil.dart';
import '../l10n/app_localizations.dart';
import '../models/exposure.dart';
import '../models/film_roll.dart';
import '../services/export_service.dart';

/// A developed roll as a strip of negatives on a light table.
class NegativesScreen extends StatefulWidget {
  final FilmRoll filmRoll;
  final List<Exposure> exposures;

  const NegativesScreen({
    super.key,
    required this.filmRoll,
    required this.exposures,
  });

  @override
  State<NegativesScreen> createState() => _NegativesScreenState();
}

class _NegativesScreenState extends State<NegativesScreen> {
  late final FilmStripStyle _style =
      FilmStripStyle.forStock(widget.filmRoll.filmStockId);
  bool _saving = false;

  Future<String> _renderSheet() {
    final l = AppLocalizations.of(context)!;
    return ExportService.contactSheet(
      widget.filmRoll,
      widget.exposures,
      countLabel: l.galleryPhotoCount(widget.exposures.length),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final path = await _renderSheet();
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putImage(path, album: 'Negativo');
      messenger.showSnackBar(SnackBar(
        content: Text(l.negativesSaved),
        action: SnackBarAction(
          label: l.galleryShare,
          onPressed: () => Share.shareXFiles(
            [XFile(path, mimeType: 'image/jpeg')],
            subject: widget.filmRoll.name,
          ),
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(l.negativesSaveFailed(
            e is GalException ? e.type.message : e.toString())),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openLoupe(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NegativeLoupe(
          filmRoll: widget.filmRoll,
          exposures: widget.exposures,
          initialIndex: index,
          style: _style,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final stripWidth = min(width * 0.72, 380.0);
    final segment = filmSegmentSize(stripWidth / kFilmWidthMm, Axis.vertical);
    final cacheWidth =
        (segment.width * MediaQuery.devicePixelRatioOf(context)).round();

    return Scaffold(
      backgroundColor: kLightTableColor,
      appBar: AppBar(
        backgroundColor: kLightTableColor,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.negativesTitle),
            Text(
              widget.filmRoll.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.negativesSave,
            onPressed: _saving || widget.exposures.isEmpty ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_alt),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            colors: [kLightTableColor, Color(0xFFF1EBDD)],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 48),
          itemCount: widget.exposures.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Text(
                  l.negativesHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              );
            }
            final index = i - 1;
            final exposure = widget.exposures[index];
            return Center(
              child: GestureDetector(
                onTap: () => _openLoupe(index),
                child: SizedBox.fromSize(
                  size: segment,
                  child: DecodedImageBuilder(
                    path: exposure.imagePath,
                    cacheWidth: cacheWidth,
                    builder: (context, image) => _FilmSegment(
                      index: index,
                      style: _style,
                      image: image,
                      effect: FilmEffect.forExposure(exposure, widget.filmRoll),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilmSegment extends StatelessWidget {
  final int index;
  final FilmStripStyle style;
  final ui.Image? image;
  final FilmEffect? effect;

  const _FilmSegment({
    required this.index,
    required this.style,
    required this.image,
    required this.effect,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FilmSegmentPainter(
          index: index,
          style: style,
          image: image,
          effect: effect,
          tilt: (effect?.isRare ?? false) ? FoilTilt.instance : null,
        ),
      ),
    );
  }
}

class _FilmSegmentPainter extends CustomPainter {
  final int index;
  final FilmStripStyle style;
  final ui.Image? image;
  final FilmEffect? effect;
  final ValueListenable<Offset>? tilt;

  _FilmSegmentPainter({
    required this.index,
    required this.style,
    required this.image,
    required this.effect,
    required this.tilt,
  }) : super(repaint: tilt);

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
      tilt: tilt?.value ?? Offset.zero,
    );
  }

  @override
  bool shouldRepaint(_FilmSegmentPainter old) =>
      old.index != index ||
      old.image != image ||
      old.effect?.serialized != effect?.serialized ||
      old.style != style ||
      old.tilt != tilt;
}

// ─── Loupe ────────────────────────────────────────────────────────────────────

/// One frame held up to the light, flippable between negative and print.
class _NegativeLoupe extends StatefulWidget {
  final FilmRoll filmRoll;
  final List<Exposure> exposures;
  final int initialIndex;
  final FilmStripStyle style;

  const _NegativeLoupe({
    required this.filmRoll,
    required this.exposures,
    required this.initialIndex,
    required this.style,
  });

  @override
  State<_NegativeLoupe> createState() => _NegativeLoupeState();
}

class _NegativeLoupeState extends State<_NegativeLoupe> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _negative = true;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final exposure = widget.exposures[_index];
    final effect = FilmEffect.forExposure(exposure, widget.filmRoll);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          l.galleryFrameOf(exposure.order, widget.exposures.length),
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: widget.exposures.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final e = widget.exposures[i];
                return GestureDetector(
                  onTap: () => setState(() => _negative = !_negative),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: EffectPhoto(
                        key: ValueKey('${e.id}-$_negative'),
                        imagePath: e.imagePath,
                        effect: FilmEffect.forExposure(e, widget.filmRoll),
                        negative: _negative,
                        negativeBase: widget.style.base,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (effect?.isRare ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l.negativesFoilHint,
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SegmentedButton<bool>(
                style: SegmentedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  selectedForegroundColor: Colors.black,
                  selectedBackgroundColor: const Color(0xFFD4A853),
                  side: const BorderSide(color: Colors.white24),
                ),
                segments: [
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.invert_colors),
                    label: Text(l.negativesNegative),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.photo_outlined),
                    label: Text(l.negativesPrint),
                  ),
                ],
                selected: {_negative},
                onSelectionChanged: (s) => setState(() => _negative = s.first),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
