import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/film_roll.dart';
import '../models/film_stock.dart';
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
          filmRoll: widget.filmRoll,
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.galleryMaxThumbnail),
            duration: const Duration(seconds: 2),
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
        SnackBar(
            content: Text(AppLocalizations.of(context)!.galleryThumbnailUpdated),
            duration: const Duration(seconds: 2)),
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
            tooltip: l.galleryEditThumbnail,
            onPressed: _enterThumbnailSelect,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l.gallerySharePhotos,
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
    final l = AppLocalizations.of(context)!;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() => _mode = _SelectMode.none),
      ),
      title: Text(l.gallerySelectThumbnail),
      actions: [
        TextButton(
          onPressed: _saveThumbnailSelection,
          child: Text(l.galleryShare),
        ),
      ],
    );
  }

  AppBar _buildShareAppBar() {
    final l = AppLocalizations.of(context)!;
    final allSelected = _selectedShareIds.length == _exposures.length;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() => _mode = _SelectMode.none),
      ),
      title: Text(
        _selectedShareIds.isEmpty
            ? l.gallerySelectPhotos
            : l.gallerySelectedCount(_selectedShareIds.length),
      ),
      actions: [
        TextButton(
          onPressed: _selectAllForShare,
          child: Text(allSelected ? l.galleryDeselectAll : l.gallerySelectAll),
        ),
      ],
    );
  }

  Widget _buildThumbnailBottomBar() {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          '${l.gallerySelectedCount(_selectedThumbnailIds.length)}/4  ·  ${l.gallerySelectThumbnail}',
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
          label: Text(AppLocalizations.of(context)!.galleryShareCount(count)),
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
  final FilmRoll filmRoll;

  const _FullscreenViewer({
    required this.exposures,
    required this.initialIndex,
    required this.filmRoll,
  });

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _barsVisible = true;
  late AnimationController _barsAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _barsAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _barsAnimation.dispose();
    super.dispose();
  }

  void _toggleBars() {
    setState(() => _barsVisible = !_barsVisible);
    if (_barsVisible) {
      _barsAnimation.forward();
    } else {
      _barsAnimation.reverse();
    }
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

  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PhotoInfoSheet(
        exposure: widget.exposures[_currentIndex],
        filmRoll: widget.filmRoll,
        totalFrames: widget.exposures.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final exposure = widget.exposures[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: FadeTransition(
          opacity: _barsAnimation,
          child: AppBar(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
            title: Text(
              l.galleryFrameOf(exposure.order, widget.exposures.length),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () => _showInfo(context),
                tooltip: l.photoInfoTitle,
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: _share,
                tooltip: l.galleryShare,
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -400) _showInfo(context);
        },
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              pageController: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: widget.exposures.length,
              builder: (context, i) {
                final exp = widget.exposures[i];
                final file = File(exp.imagePath);
                if (!file.existsSync()) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.white38, size: 64),
                    ),
                    childSize: const Size(64, 64),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.contained,
                  );
                }
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(file),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: 4.0,
                  initialScale: PhotoViewComputedScale.contained,
                  basePosition: Alignment.center,
                  gestureDetectorBehavior: HitTestBehavior.opaque,
                  onTapUp: (_, __, ___) => _toggleBars(),
                );
              },
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
            // Swipe-up hint at the bottom
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _barsAnimation,
                child: Column(
                  children: [
                    const Icon(Icons.keyboard_arrow_up,
                        color: Colors.white54, size: 20),
                    Text(
                      AppLocalizations.of(context)!.photoInfoTitle,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photo info sheet ─────────────────────────────────────────────────────────

class _PhotoInfoSheet extends StatelessWidget {
  final Exposure exposure;
  final FilmRoll filmRoll;
  final int totalFrames;

  const _PhotoInfoSheet({
    required this.exposure,
    required this.filmRoll,
    required this.totalFrames,
  });

  String _formatFileSize(String path) {
    final file = File(path);
    if (!file.existsSync()) return '—';
    final bytes = file.lengthSync();
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final stock = FilmStock.fromId(filmRoll.filmStockId);
    final dateStr = DateFormat('EEEE, MMMM d, yyyy  ·  HH:mm').format(
      exposure.capturedAt.toLocal(),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              l.photoInfoTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            _InfoRow(
              icon: Icons.photo_camera_outlined,
              label: l.photoInfoFrame,
              value: '${exposure.order} / $totalFrames',
              cs: cs,
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: l.photoInfoDate,
              value: dateStr,
              cs: cs,
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.photo_library_outlined,
              label: l.photoInfoRoll,
              value: filmRoll.name,
              cs: cs,
            ),
            if (stock != null) ...[
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.lens_outlined,
                label: l.photoInfoFilmStock,
                value: '${stock.brand}  ${stock.name}',
                cs: cs,
                accentColor: stock.accentColor,
              ),
            ],
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.sd_card_outlined,
              label: l.photoInfoSize,
              value: _formatFileSize(exposure.imagePath),
              cs: cs,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final Color? accentColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? cs.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.outline,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
