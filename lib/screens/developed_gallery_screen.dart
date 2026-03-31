import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/film_roll.dart';
import '../models/exposure.dart';
import '../services/hive_service.dart';
import '../services/google_photos_service.dart';

class DevelopedGalleryScreen extends StatefulWidget {
  final FilmRoll filmRoll;

  const DevelopedGalleryScreen({super.key, required this.filmRoll});

  @override
  State<DevelopedGalleryScreen> createState() =>
      _DevelopedGalleryScreenState();
}

class _DevelopedGalleryScreenState extends State<DevelopedGalleryScreen> {
  List<Exposure> _exposures = [];
  bool _exporting = false;
  double _exportProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadExposures();
  }

  void _loadExposures() {
    setState(() {
      _exposures =
          HiveService.getExposuresForRoll(widget.filmRoll.id);
    });
  }

  Future<void> _exportToGooglePhotos() async {
    final paths = _exposures
        .map((e) => e.imagePath)
        .where((p) => File(p).existsSync())
        .toList();

    if (paths.isEmpty) return;

    setState(() {
      _exporting = true;
      _exportProgress = 0;
    });

    try {
      final url = await GooglePhotosService.createAlbumWithPhotos(
        albumTitle: widget.filmRoll.name,
        imagePaths: paths,
        onProgress: (p) => setState(() => _exportProgress = p),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Album created! $url'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _openPhoto(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenViewer(
          exposures: _exposures,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filmRoll.name),
        actions: [
          if (_exporting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: _exportProgress > 0 ? _exportProgress : null,
                ),
              ),
            )
          else if (_exposures.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined),
              tooltip: 'Export to Google Photos',
              onPressed: _exportToGooglePhotos,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l.galleryPhotoCount(_exposures.length),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ),
      ),
      body: _exposures.isEmpty
          ? _buildEmpty(l)
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemCount: _exposures.length,
              itemBuilder: (context, i) {
                final exposure = _exposures[i];
                return GestureDetector(
                  onTap: () => _openPhoto(i),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PhotoTile(imagePath: exposure.imagePath),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${exposure.order}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmpty(AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(l.galleryNoPhotos,
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String imagePath;

  const _PhotoTile({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    if (!file.existsSync()) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Icon(Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.outline),
      );
    }
    return Image.file(file, fit: BoxFit.cover);
  }
}

class _FullscreenViewer extends StatefulWidget {
  final List<Exposure> exposures;
  final int initialIndex;

  const _FullscreenViewer({
    required this.exposures,
    required this.initialIndex,
  });

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final exposure = widget.exposures[_currentIndex];
    final file = File(exposure.imagePath);
    if (!file.existsSync()) return;
    await Share.shareXFiles(
      [XFile(exposure.imagePath)],
      text: 'Frame ${exposure.order}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final exposure = widget.exposures[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          l.galleryFrameOf(exposure.order, widget.exposures.length),
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: _share,
            tooltip: l.galleryShare,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.exposures.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, i) {
          final exp = widget.exposures[i];
          final file = File(exp.imagePath);
          if (!file.existsSync()) {
            return const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.white38, size: 64),
            );
          }
          return InteractiveViewer(
            child: Center(
              child: Image.file(file, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
