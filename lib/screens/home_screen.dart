import 'package:flutter/material.dart';
import '../models/film_roll.dart';
import '../models/film_stock.dart';
import '../services/hive_service.dart';
import '../services/film_service.dart';
import '../services/scoring_service.dart';
import 'new_roll_screen.dart';
import 'viewfinder_screen.dart';
import 'film_roll_detail_screen.dart';
import 'developed_gallery_screen.dart';
import 'settings_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<FilmRoll> _rolls = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRolls();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDevelopmentAndReload();
    }
  }

  Future<void> _checkDevelopmentAndReload() async {
    await FilmService.checkDevelopmentCompletions();
    _loadRolls();
  }

  void _loadRolls() {
    setState(() {
      _rolls = HiveService.getAllFilmRolls();
    });
  }

  List<FilmRoll> get _activeRolls =>
      _rolls.where((r) => r.status == 'active').toList();

  List<FilmRoll> get _developingRolls =>
      _rolls.where((r) => r.status == 'developing').toList();

  List<FilmRoll> get _developedRolls =>
      _rolls.where((r) => r.status == 'developed').toList();

  Future<void> _openViewfinder(FilmRoll roll) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewfinderScreen(filmRoll: roll)),
    );
    _loadRolls();
  }

  Future<void> _openNewRoll() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewRollScreen()),
    );
    _loadRolls();
  }

  Future<void> _openDetail(FilmRoll roll) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FilmRollDetailScreen(filmRoll: roll)),
    );
    _loadRolls();
  }

  Future<void> _openGallery(FilmRoll roll) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DevelopedGalleryScreen(filmRoll: roll)),
    );
    _loadRolls();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Negativo',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.5),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProgressScreen()),
              );
              setState(() {});
            },
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    '${ScoringService.points}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadRolls();
            },
          ),
        ],
      ),
      body: _rolls.isEmpty ? _buildEmptyState() : _buildRollsList(),
      floatingActionButton: _activeRolls.length < ScoringService.maxActiveSlots
          ? FloatingActionButton.extended(
              onPressed: _openNewRoll,
              icon: const Icon(Icons.camera_roll),
              label: const Text('Load Film'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_roll_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No film loaded',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Load a film roll to start shooting.\nEach roll gives you 12, 24, or 36 frames.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _openNewRoll,
              icon: const Icon(Icons.camera_roll),
              label: const Text('Load Film Roll'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRollsList() {
    return RefreshIndicator(
      onRefresh: _checkDevelopmentAndReload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (_activeRolls.isNotEmpty) ...[
            ..._activeRolls.map(_buildActiveRollCard),
            const SizedBox(height: 24),
          ],
          if (_developingRolls.isNotEmpty) ...[
            _buildSectionHeader('Developing', Icons.hourglass_top_rounded),
            const SizedBox(height: 8),
            ..._developingRolls.map(_buildDevelopingCard),
            const SizedBox(height: 24),
          ],
          if (_developedRolls.isNotEmpty) ...[
            _buildSectionHeader('Developed', Icons.photo_library_outlined),
            const SizedBox(height: 8),
            ..._developedRolls.map(_buildDevelopedCard),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                letterSpacing: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildActiveRollCard(FilmRoll roll) {
    final cs = Theme.of(context).colorScheme;
    final used = roll.exposureCount;
    final total = roll.capacity;

    return Card(
      color: cs.surfaceContainerHighest,
      child: InkWell(
        onTap: () => _openDetail(roll),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'LOADED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 20, color: cs.outline),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                roll.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _buildFilmStockBadge(roll),
              const SizedBox(height: 14),
              _buildFilmStrip(used, total),
              const SizedBox(height: 6),
              Text(
                '$used / $total frames used',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.outline),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openViewfinder(roll),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Shoot'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => _openDetail(roll),
                    child: const Text('Develop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilmStockBadge(FilmRoll roll) {
    final stock = FilmStock.fromId(roll.filmStockId);
    if (stock == null) return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: stock.accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${stock.brand}  ${stock.name}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: stock.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
        ),
      ],
    );
  }

  Widget _buildFilmStrip(int used, int total) {
    return Row(
      children: List.generate(total, (i) {
        final isUsed = i < used;
        return Expanded(
          child: Container(
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isUsed
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDevelopingCard(FilmRoll roll) {
    final cs = Theme.of(context).colorScheme;
    final remaining = roll.remainingDevelopmentTime;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: cs.surfaceContainerLow,
        child: InkWell(
          onTap: () => _openDetail(roll),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hourglass_top_rounded,
                      color: cs.onSecondaryContainer),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roll.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        remaining != null && remaining.inSeconds > 0
                            ? _formatDuration(remaining)
                            : 'Almost ready…',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chevron_right, size: 20, color: cs.outline),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        await FilmService.instantDevelop(roll);
                        _loadRolls();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DEV NOW',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevelopedCard(FilmRoll roll) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: cs.surfaceContainerLow,
        child: InkWell(
          onTap: () => _openGallery(roll),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library,
                      color: cs.onTertiaryContainer),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roll.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${roll.exposureCount} photos',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _openGallery(roll),
                  child: const Text('View'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays >= 1) {
      final hours = d.inHours % 24;
      return '${d.inDays}d ${hours}h remaining';
    } else if (d.inHours >= 1) {
      final minutes = d.inMinutes % 60;
      return '${d.inHours}h ${minutes}m remaining';
    } else {
      return '${d.inMinutes}m remaining';
    }
  }
}
