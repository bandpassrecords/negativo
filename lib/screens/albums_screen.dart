import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/film_roll.dart';
import '../models/film_stock.dart';
import '../services/hive_service.dart';
import '../services/film_service.dart';
import 'developed_gallery_screen.dart';

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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DevelopedGalleryScreen(filmRoll: roll)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.albumsTitle),
      ),
      body: _rolls.isEmpty
          ? _buildEmpty(l)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: _rolls.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _AlbumCard(
                  roll: _rolls[i],
                  onTap: () => _openGallery(_rolls[i]),
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

// ─────────────────────────────────────────────────────────────────────────────

class _AlbumCard extends StatelessWidget {
  final FilmRoll roll;
  final VoidCallback onTap;

  const _AlbumCard({required this.roll, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final stock = FilmStock.fromId(roll.filmStockId);
    final exposures = HiveService.getExposuresForRoll(roll.id);
    final coverPath = exposures.isNotEmpty ? exposures.first.imagePath : null;

    return Card(
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              // Cover photo or placeholder
              SizedBox(
                width: 100,
                height: 100,
                child: coverPath != null && File(coverPath).existsSync()
                    ? Image.file(
                        File(coverPath),
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.photo_library,
                            color: cs.outline, size: 32),
                      ),
              ),

              // Info
              Expanded(
                child: Padding(
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
                                ?.copyWith(fontWeight: FontWeight.w700),
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
                                    borderRadius: BorderRadius.circular(2),
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
                            l.albumsPhotoCount(exposures.length),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.outline),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right,
                              size: 18, color: cs.outline),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
