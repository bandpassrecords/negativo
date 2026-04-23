import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/film_roll.dart';
import '../models/film_stock.dart';
import '../models/exposure.dart';
import '../services/hive_service.dart';
import '../services/film_service.dart';
import 'developed_gallery_screen.dart';
import 'reveal_gallery_screen.dart';

// ─── Preset palette ──────────────────────────────────────────────────────────

const _kColorOptions = <String?>[
  null,
  '#EF5350',
  '#FF7043',
  '#FFCA28',
  '#66BB6A',
  '#26C6DA',
  '#42A5F5',
  '#7E57C2',
  '#EC407A',
  '#A1887F',
];

const _kPatternOptions = <String?>[null, 'dots', 'stripes', 'diagonal', 'crosshatch'];

Color? _parseHex(String? hex) {
  if (hex == null) return null;
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen>
    with WidgetsBindingObserver {
  List<FilmRoll> _rolls = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  void _load() {
    setState(() {
      _rolls = HiveService.getFilmRollsByStatus('developed');
    });
  }

  Future<void> _refresh() async {
    await FilmService.checkDevelopmentCompletions();
    _load();
  }

  void _openGallery(FilmRoll roll) {
    final settings = HiveService.getSettings();
    final exposures = HiveService.getExposuresForRoll(roll.id);
    final allRevealed = !settings.albumRevealEnabled ||
        exposures.isEmpty ||
        exposures.every((e) => roll.revealedExposureIds.contains(e.id));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => allRevealed
            ? DevelopedGalleryScreen(filmRoll: roll)
            : RevealGalleryScreen(filmRoll: roll),
      ),
    ).then((_) => _load());
  }

  void _showCustomization(FilmRoll roll) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CustomizationSheet(
        roll: roll,
        onChanged: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.albumsTitle)),
      body: _rolls.isEmpty
          ? _buildEmpty(l)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: _rolls.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final roll = _rolls[i];
                  final exposures = HiveService.getExposuresForRoll(roll.id);
                  final settings = HiveService.getSettings();
                  final revealed = !settings.albumRevealEnabled ||
                      exposures.isEmpty ||
                      exposures
                          .every((e) => roll.revealedExposureIds.contains(e.id));
                  return _AlbumCard(
                    roll: roll,
                    exposures: exposures,
                    isRevealed: revealed,
                    onTap: () => _openGallery(roll),
                    onLongPress: () => _showCustomization(roll),
                  );
                },
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
              size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 20),
          Text(l.albumsEmpty,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            l.albumsEmptySub,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Album card ───────────────────────────────────────────────────────────────

class _AlbumCard extends StatelessWidget {
  final FilmRoll roll;
  final List<Exposure> exposures;
  final bool isRevealed;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AlbumCard({
    required this.roll,
    required this.exposures,
    required this.isRevealed,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stock = FilmStock.fromId(roll.filmStockId);
    final accentColor = _parseHex(roll.albumColor);
    final pattern = roll.albumPattern;

    // Thumbnail photos: prefer user-selected, else first 1-4
    final thumbIds = roll.thumbnailExposureIds;
    final thumbExposures = thumbIds.isNotEmpty
        ? thumbIds
            .map((id) => exposures.firstWhere(
                  (e) => e.id == id,
                  orElse: () => exposures.first,
                ))
            .take(4)
            .toList()
        : exposures.take(4).toList();

    return Card(
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: 100,
          child: Stack(
            children: [
              Row(
                children: [
                  // Thumbnail area
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: isRevealed
                        ? _PhotoGrid(exposures: thumbExposures)
                        : _UnrevealedPlaceholder(
                            pattern: pattern,
                            accentColor: accentColor,
                          ),
                  ),
                  // Info area with optional pattern background
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (pattern != null)
                          CustomPaint(
                            painter: _PatternPainter(
                              pattern: pattern,
                              color: accentColor ??
                                  cs.onSurface.withValues(alpha: 0.5),
                              opacity: 0.06,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    roll.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (stock != null) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          width: 3,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: stock.accentColor,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '${stock.brand}  ${stock.name}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: stock.accentColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.photo_outlined,
                                      size: 14, color: cs.outline),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .albumsPhotoCount(exposures.length),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.outline),
                                  ),
                                  const Spacer(),
                                  if (!isRevealed)
                                    Icon(Icons.lock_outline,
                                        size: 14, color: cs.outline),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right,
                                      size: 18, color: cs.outline),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Color accent bar overlaid on left edge
              if (accentColor != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: ColoredBox(color: accentColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Photo grid (1–4 photos) ─────────────────────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  final List<Exposure> exposures;

  const _PhotoGrid({required this.exposures});

  @override
  Widget build(BuildContext context) {
    if (exposures.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(Icons.photo_library,
            color: Theme.of(context).colorScheme.outline, size: 32),
      );
    }

    final count = exposures.length.clamp(1, 4);
    if (count == 1) return _tile(exposures[0]);

    if (count == 2) {
      return Row(children: [
        Expanded(child: _tile(exposures[0])),
        const SizedBox(width: 1),
        Expanded(child: _tile(exposures[1])),
      ]);
    }

    if (count == 3) {
      return Row(children: [
        Expanded(child: _tile(exposures[0])),
        const SizedBox(width: 1),
        Expanded(
          child: Column(children: [
            Expanded(child: _tile(exposures[1])),
            const SizedBox(height: 1),
            Expanded(child: _tile(exposures[2])),
          ]),
        ),
      ]);
    }

    // 4 photos
    return Column(children: [
      Expanded(
        child: Row(children: [
          Expanded(child: _tile(exposures[0])),
          const SizedBox(width: 1),
          Expanded(child: _tile(exposures[1])),
        ]),
      ),
      const SizedBox(height: 1),
      Expanded(
        child: Row(children: [
          Expanded(child: _tile(exposures[2])),
          const SizedBox(width: 1),
          Expanded(child: _tile(exposures[3])),
        ]),
      ),
    ]);
  }

  Widget _tile(Exposure e) {
    final file = File(e.imagePath);
    if (!file.existsSync()) {
      return const ColoredBox(color: Color(0xFF2A2A2A));
    }
    return Image.file(file, fit: BoxFit.cover);
  }
}

// ─── Unrevealed placeholder ───────────────────────────────────────────────────

class _UnrevealedPlaceholder extends StatelessWidget {
  final String? pattern;
  final Color? accentColor;

  const _UnrevealedPlaceholder({this.pattern, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final base = accentColor ?? const Color(0xFFB8660A);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF161616)),
        if (pattern != null)
          CustomPaint(
            painter: _PatternPainter(
              pattern: pattern!,
              color: base,
              opacity: 0.25,
            ),
          ),
        // Sprocket holes top and bottom
        Column(
          children: [
            _SprocketStrip(color: base.withValues(alpha: 0.35)),
            Expanded(
              child: Center(
                child: Icon(
                  Icons.camera_outlined,
                  color: base.withValues(alpha: 0.5),
                  size: 32,
                ),
              ),
            ),
            _SprocketStrip(color: base.withValues(alpha: 0.35)),
          ],
        ),
      ],
    );
  }
}

class _SprocketStrip extends StatelessWidget {
  final Color color;
  const _SprocketStrip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      color: const Color(0xFF0D0D0D),
      child: Row(
        children: List.generate(
          7,
          (_) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pattern painter ─────────────────────────────────────────────────────────

class _PatternPainter extends CustomPainter {
  final String pattern;
  final Color color;
  final double opacity;

  const _PatternPainter({
    required this.pattern,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    switch (pattern) {
      case 'dots':
        paint.style = PaintingStyle.fill;
        for (double x = 8; x < size.width; x += 14) {
          for (double y = 8; y < size.height; y += 14) {
            canvas.drawCircle(Offset(x, y), 2, paint);
          }
        }
      case 'stripes':
        for (double y = 0; y < size.height; y += 9) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      case 'diagonal':
        for (double i = -size.height; i < size.width + size.height; i += 12) {
          canvas.drawLine(
              Offset(i, 0), Offset(i + size.height, size.height), paint);
        }
      case 'crosshatch':
        for (double x = 0; x < size.width; x += 10) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (double y = 0; y < size.height; y += 10) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.pattern != pattern || old.color != color || old.opacity != opacity;
}

// ─── Customization bottom sheet ───────────────────────────────────────────────

class _CustomizationSheet extends StatefulWidget {
  final FilmRoll roll;
  final VoidCallback onChanged;

  const _CustomizationSheet({
    required this.roll,
    required this.onChanged,
  });

  @override
  State<_CustomizationSheet> createState() => _CustomizationSheetState();
}

class _CustomizationSheetState extends State<_CustomizationSheet> {
  late String? _color;
  late String? _pattern;

  @override
  void initState() {
    super.initState();
    _color = widget.roll.albumColor;
    _pattern = widget.roll.albumPattern;
  }

  Future<void> _save() async {
    widget.roll.albumColor = _color;
    widget.roll.albumPattern = _pattern;
    await HiveService.saveFilmRoll(widget.roll);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const SizedBox(height: 16),
            Text(
              widget.roll.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Color picker
            Text(AppLocalizations.of(context)!.albumCustomizeColor,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.outline,
                      letterSpacing: 1.2,
                    )),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _kColorOptions.map((hex) {
                  final isSelected = _color == hex;
                  final col = _parseHex(hex);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _color = hex);
                      _save();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: col ?? cs.surfaceContainerHighest,
                        border: Border.all(
                          color: isSelected
                              ? cs.primary
                              : cs.outline.withValues(alpha: 0.3),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: hex == null
                          ? Icon(Icons.block,
                              size: 16, color: cs.outline.withValues(alpha: 0.5))
                          : isSelected
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Pattern picker
            Text(AppLocalizations.of(context)!.albumCustomizePattern,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.outline,
                      letterSpacing: 1.2,
                    )),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _kPatternOptions.map((p) {
                  final isSelected = _pattern == p;
                  final accentCol =
                      _parseHex(_color) ?? cs.primary;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _pattern = p);
                      _save();
                    },
                    child: Container(
                      width: 56,
                      height: 52,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? cs.primary
                              : cs.outline.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: p == null
                            ? Center(
                                child: Icon(Icons.block,
                                    size: 18,
                                    color: cs.outline.withValues(alpha: 0.5)))
                            : CustomPaint(
                                painter: _PatternPainter(
                                  pattern: p,
                                  color: accentCol,
                                  opacity: 0.5,
                                ),
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),

            // Edit thumbnail
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.grid_view_outlined, color: cs.primary),
              title: Text(AppLocalizations.of(context)!.albumEditThumbnail),
              subtitle: Text(AppLocalizations.of(context)!.albumEditThumbnailSub),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DevelopedGalleryScreen(
                      filmRoll: widget.roll,
                      openInThumbnailSelect: true,
                    ),
                  ),
                ).then((_) => widget.onChanged());
              },
            ),
          ],
        ),
      ),
    );
  }
}
