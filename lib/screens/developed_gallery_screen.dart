import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/film_roll.dart';
import '../models/exposure.dart';
import '../services/hive_service.dart';

enum _SelectMode { none, thumbnail, share }

class DevelopedGalleryScreen extends StatefulWidget {
  final FilmRoll filmRoll;
  final bool openInThumbnailSelect;

  const DevelopedGalleryScreen({
    super.key,
    required this.filmRoll,
    this.openInThumbnailSelect = false,
  });

  @override
  State<DevelopedGalleryScreen> createState() =>
      _DevelopedGalleryScreenState();
}

class _DevelopedGalleryScreenState extends State<DevelopedGalleryScreen> {
  List<Exposure> _exposures = [];
  _SelectMode _mode = _SelectMode.none;
  late Set<String> _selectedThumbnailIds;
  final Set<String> _selectedShareIds = {};
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadExposures();
    _selectedThumbnailIds = Set.from(widget.filmRoll.thumbnailExposureIds);
    if (widget.openInThumbnailSelect) {
      _mode = _SelectMode.thumbnail;
    }
  }

  void _loadExposures() {
    setState(() {
      _exposures = HiveService.getExposuresForRoll(widget.filmRoll.id);
    });
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

  // ── Thumbnail select ────────────────────────────────────────────────────────

  void _enterThumbnailSelect() {
    setState(() {
      _mode = _SelectMode.thumbnail;
      _selectedThumbnailIds = Set.from(widget.filmRoll.thumbnailExposureIds);
    });
  }

  void _toggleThumbnailSelection(String exposureId) {
    setState(() {
      if (_selectedThumbnailIds.contains(exposureId)) {
        _selectedThumbnailIds.remove(exposureId);
      } else if (_selectedThumbnailIds.length < 4) {
        _selectedThumbnailIds.add(exposureId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 4 photos for the thumbnail'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _saveThumbnailSelection() async {
    widget.filmRoll.thumbnailExposureIds = _exposures
        .where((e) => _selectedThumbnailIds.contains(e.id))
        .map((e) => e.id)
        .toList();
    await HiveService.saveFilmRoll(widget.filmRoll);
    if (mounted) {
      setState(() => _mode = _SelectMode.none);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Thumbnail updated'),
            duration: Duration(seconds: 2)),
      );
    }
  }

  // ── Share select ────────────────────────────────────────────────────────────

  void _enterShareSelect() {
    setState(() {
      _mode = _SelectMode.share;
      _selectedShareIds.clear();
    });
  }

  void _toggleShareSelection(String exposureId) {
    setState(() {
      if (_selectedShareIds.contains(exposureId)) {
        _selectedShareIds.remove(exposureId);
      } else {
        _selectedShareIds.add(exposureId);
      }
    });
  }

  void _selectAllForShare() {
    setState(() {
      if (_selectedShareIds.length == _exposures.length) {
        _selectedShareIds.clear();
      } else {
        _selectedShareIds.addAll(_exposures.map((e) => e.id));
      }
    });
  }

  Future<void> _shareSelected() async {
    final files = _exposures
        .where((e) => _selectedShareIds.contains(e.id))
        .map((e) => e.imagePath)
        .where((p) => File(p).existsSync())
        .map((p) => XFile(p))
        .toList();

    if (files.isEmpty) return;

    setState(() => _sharing = true);
    try {
      await Share.shareXFiles(
        files,
        subject: widget.filmRoll.name,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: switch (_mode) {
        _SelectMode.thumbnail => _buildThumbnailAppBar(),
        _SelectMode.share => _buildShareAppBar(),
        _SelectMode.none => _buildNormalAppBar(l),
      },
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
              itemBuilder: (context, i) => _buildTile(context, i),
            ),
      bottomNavigationBar: switch (_mode) {
        _SelectMode.thumbnail => _buildThumbnailBottomBar(),
        _SelectMode.share => _buildShareBottomBar(),
        _SelectMode.none => null,
      },
    );
  }

  Widget _buildTile(BuildContext context, int i) {
    final exposure = _exposures[i];

    switch (_mode) {
      case _SelectMode.none:
        return GestureDetector(
          onTap: () => _openPhoto(i),
          onLongPress: _enterShareSelect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _PhotoTile(imagePath: exposure.imagePath),
              Positioned(
                bottom: 4,
                left: 4,
                child: _FrameBadge(label: '${exposure.order}'),
              ),
            ],
          ),
        );

      case _SelectMode.thumbnail:
        final isSelected = _selectedThumbnailIds.contains(exposure.id);
        final selectionIndex = _exposures
                .where((e) => _selectedThumbnailIds.contains(e.id))
                .toList()
                .indexOf(exposure) +
            1;
        return GestureDetector(
          onTap: () => _toggleThumbnailSelection(exposure.id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _PhotoTile(imagePath: exposure.imagePath),
              if (!isSelected) Container(color: Colors.black45),
              Positioned(
                top: 6,
                right: 6,
                child: isSelected
                    ? _SelectionBadge(
                        label: '$selectionIndex',
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : const _EmptyBadge(),
              ),
            ],
          ),
        );

      case _SelectMode.share:
        final isSelected = _selectedShareIds.contains(exposure.id);
        return GestureDetector(
          onTap: () => _toggleShareSelection(exposure.id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _PhotoTile(imagePath: exposure.imagePath),
              if (!isSelected) Container(color: Colors.black38),
              Positioned(
                top: 6,
                right: 6,
                child: isSelected
                    ? _SelectionBadge(
                        label: '',
                        color: Theme.of(context).colorScheme.primary,
                        icon: Icons.check,
                      )
                    : const _EmptyBadge(),
              ),
            ],
          ),
        );
    }
  }

  AppBar _buildNormalAppBar(AppLocalizations l) {
    return AppBar(
      title: Text(widget.filmRoll.name),
      actions: [
        if (_exposures.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.grid_view_outlined),
            tooltip: 'Edit thumbnail',
            onPressed: _enterThumbnailSelect,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share photos',
            onPressed: _enterShareSelect,
          ),
        ],
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
    );
  }

  AppBar _buildThumbnailAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() => _mode = _SelectMode.none),
      ),
      title: const Text('Select thumbnail'),
      actions: [
        TextButton(
          onPressed: _saveThumbnailSelection,
          child: const Text('Done'),
        ),
      ],
    );
  }

  AppBar _buildShareAppBar() {
    final allSelected = _selectedShareIds.length == _exposures.length;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() => _mode = _SelectMode.none),
      ),
      title: Text(
        _selectedShareIds.isEmpty
            ? 'Select photos'
            : '${_selectedShareIds.length} selected',
      ),
      actions: [
        TextButton(
          onPressed: _selectAllForShare,
          child: Text(allSelected ? 'Deselect all' : 'Select all'),
        ),
      ],
    );
  }

  Widget _buildThumbnailBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          '${_selectedThumbnailIds.length}/4 selected  ·  Tap photos to select',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ),
    );
  }

  Widget _buildShareBottomBar() {
    final count = _selectedShareIds.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: FilledButton.icon(
          onPressed: count == 0 || _sharing ? null : _shareSelected,
          icon: _sharing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.share_outlined),
          label: Text(
            count == 0
                ? 'Share'
                : count == 1
                    ? 'Share 1 photo'
                    : 'Share $count photos',
          ),
        ),
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

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _FrameBadge extends StatelessWidget {
  final String label;
  const _FrameBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _SelectionBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 14, color: Colors.white)
            : Text(
                label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _EmptyBadge extends StatelessWidget {
  const _EmptyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white60, width: 1.5),
      ),
    );
  }
}

// ─── Photo tile ───────────────────────────────────────────────────────────────

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

// ─── Fullscreen viewer ────────────────────────────────────────────────────────

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
      subject: 'Frame ${exposure.order}',
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
            child: Center(child: Image.file(file, fit: BoxFit.contain)),
          );
        },
      ),
    );
  }
}
