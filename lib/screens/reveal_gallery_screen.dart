import 'package:flutter/material.dart';
import '../effects/film_effect.dart';
import '../effects/film_strip.dart';
import '../l10n/app_localizations.dart';
import '../models/film_roll.dart';
import '../models/exposure.dart';
import '../services/hive_service.dart';
import '../widgets/reveal_film_strip.dart';
import 'developed_gallery_screen.dart';

/// Developing a roll: the whole roll laid out as the strip of negatives it
/// is, the same film as the negatives viewer. Scroll down it and tap each
/// negative to develop it into its print.
class RevealGalleryScreen extends StatefulWidget {
  final FilmRoll filmRoll;

  const RevealGalleryScreen({super.key, required this.filmRoll});

  @override
  State<RevealGalleryScreen> createState() => _RevealGalleryScreenState();
}

class _RevealGalleryScreenState extends State<RevealGalleryScreen> {
  late final List<Exposure> _exposures =
      HiveService.getExposuresForRoll(widget.filmRoll.id);
  late final Set<String> _developed =
      Set.of(widget.filmRoll.revealedExposureIds);
  late final FilmStripStyle _style =
      FilmStripStyle.forStock(widget.filmRoll.filmStockId);

  bool get _allDeveloped => _developed.length >= _exposures.length;

  Future<void> _onDeveloped(Exposure exposure) async {
    setState(() => _developed.add(exposure.id));
    // Each frame gets its own chance of coming out Shiny as it develops.
    final shiny = FilmEffect.rollPhotoShiny();
    if (shiny != null) {
      exposure.filmEffect = shiny.serialized;
      await HiveService.saveExposure(exposure);
      _showShinySnackbar();
    }
    await _persist();
  }

  Future<void> _persist() async {
    widget.filmRoll.revealedExposureIds = _developed.toList();
    await HiveService.saveFilmRoll(widget.filmRoll);
  }

  Future<void> _skipAll() async {
    setState(() => _developed.addAll(_exposures.map((e) => e.id)));
    await _persist();
    if (mounted) _openGallery();
  }

  void _showShinySnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.effectShinyFound),
        backgroundColor: const Color(0xFF6A0DAD),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _openGallery() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DevelopedGalleryScreen(filmRoll: widget.filmRoll),
      ),
    );
  }

  /// Opens a developed frame in the full photo viewer — pinch to zoom, swipe
  /// up for its info — able to swipe across every frame developed so far.
  Future<void> _openPrint(Exposure exposure) async {
    final prints = [
      for (final e in _exposures)
        if (_developed.contains(e.id)) e,
    ];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(
          exposures: prints,
          initialIndex: prints.indexOf(exposure),
          filmRoll: widget.filmRoll,
        ),
      ),
    );
    // The viewer can switch a photo's foil off; show the strip as it is now.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_exposures.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openGallery());
      return const Scaffold(backgroundColor: kLightTableColor);
    }
    final l = AppLocalizations.of(context)!;
    final outline = Theme.of(context).colorScheme.outline;

    return Scaffold(
      backgroundColor: kLightTableColor,
      appBar: AppBar(
        backgroundColor: kLightTableColor,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.filmRoll.name),
            Text(
              l.revealProgress(_developed.length, _exposures.length),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: outline),
            ),
          ],
        ),
        actions: [
          if (!_allDeveloped)
            TextButton(onPressed: _skipAll, child: Text(l.revealSkipAll)),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            colors: [kLightTableColor, Color(0xFFF1EBDD)],
          ),
        ),
        child: RevealFilmStrip(
          exposures: _exposures,
          developed: _developed,
          style: _style,
          effectFor: (e) => FilmEffect.forExposure(e, widget.filmRoll),
          onDeveloped: _onDeveloped,
          onOpenPrint: _openPrint,
          hint: l.revealStripHint,
          tapToDevelop: l.revealTapToDevelop,
          footer: _allDeveloped
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Column(
                    children: [
                      Text(
                        l.revealAllDeveloped,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: outline),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _openGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(l.revealOpenGallery),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
