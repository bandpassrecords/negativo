import 'package:flutter/material.dart';
import '../models/film_stock.dart';
import '../services/film_service.dart';
import '../services/scoring_service.dart';

class NewRollScreen extends StatefulWidget {
  const NewRollScreen({super.key});

  @override
  State<NewRollScreen> createState() => _NewRollScreenState();
}

class _NewRollScreenState extends State<NewRollScreen> {
  late int _selectedCapacity;
  FilmStock _selectedStock = FilmStock.portra400;
  final _nameController = TextEditingController();
  bool _loading = false;

  static const List<int> _allCapacities = [12, 24, 36];

  @override
  void initState() {
    super.initState();
    _selectedCapacity = ScoringService.availableCapacities.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRoll() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your roll a name first')),
      );
      return;
    }
    setState(() => _loading = true);
    await FilmService.loadNewRoll(
      name,
      _selectedCapacity,
      filmStockId: _selectedStock.id,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Load Film Roll')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Film stock ─────────────────────────────────────────────────
            Text(
              'Choose film stock',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Each stock gives your photos a distinct look.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.9,
              children: FilmStock.all.map((stock) {
                final unlocked = stock.unlockFeatureId == null ||
                    ScoringService.isUnlocked(stock.unlockFeatureId!);
                return _StockCard(
                  stock: stock,
                  selected: _selectedStock.id == stock.id,
                  locked: !unlocked,
                  unlockCost: unlocked
                      ? null
                      : ScoringService.unlockCosts[stock.unlockFeatureId],
                  onTap: unlocked
                      ? () => setState(() => _selectedStock = stock)
                      : null,
                );
              }).toList(),
            ),

            const SizedBox(height: 8),
            // Description of selected stock
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Padding(
                key: ValueKey(_selectedStock.id),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  _selectedStock.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Capacity ───────────────────────────────────────────────────
            Text(
              'Choose capacity',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'How many frames does this roll have?',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 16),
            Row(
              children: _allCapacities.map((cap) {
                final unlocked =
                    ScoringService.availableCapacities.contains(cap);
                final selected = cap == _selectedCapacity;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _CapacityTile(
                      capacity: cap,
                      selected: selected,
                      locked: !unlocked,
                      onTap: unlocked
                          ? () => setState(() => _selectedCapacity = cap)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // ── Name ───────────────────────────────────────────────────────
            Text(
              'Name this roll',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'What moment or trip is this roll for?',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              autofocus: false,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Paris Trip, Summer 2024, Road Trip…',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _loadRoll(),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _loadRoll,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_roll),
                label: const Text('Load Roll'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Film stock card ──────────────────────────────────────────────────────────

class _StockCard extends StatelessWidget {
  final FilmStock stock;
  final bool selected;
  final bool locked;
  final int? unlockCost;
  final VoidCallback? onTap;

  const _StockCard({
    required this.stock,
    required this.selected,
    required this.locked,
    required this.unlockCost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: locked
              ? cs.surfaceContainerLow.withValues(alpha: 0.5)
              : selected
                  ? cs.surfaceContainerHighest
                  : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected && !locked ? stock.accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 5,
                color: locked
                    ? cs.outline.withValues(alpha: 0.3)
                    : stock.accentColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stock.brand,
                        style: TextStyle(
                          fontSize: 10,
                          color: locked ? cs.outline.withValues(alpha: 0.5) : cs.outline,
                        ),
                      ),
                      Text(
                        stock.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: locked ? cs.onSurface.withValues(alpha: 0.4) : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        locked ? '${unlockCost ?? '?'} pts to unlock' : stock.tagline,
                        style: TextStyle(
                          fontSize: 9,
                          color: locked
                              ? cs.outline.withValues(alpha: 0.5)
                              : stock.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (locked)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.lock_outline,
                      size: 14, color: cs.outline.withValues(alpha: 0.4)),
                )
              else if (selected)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle,
                      size: 16, color: stock.accentColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Capacity tile ────────────────────────────────────────────────────────────

class _CapacityTile extends StatelessWidget {
  final int capacity;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  const _CapacityTile({
    required this.capacity,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: locked
              ? cs.surfaceContainerLow.withValues(alpha: 0.5)
              : selected
                  ? cs.primaryContainer
                  : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            if (locked)
              Icon(Icons.lock_outline,
                  size: 22, color: cs.outline.withValues(alpha: 0.5))
            else
              Text(
                '$capacity',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              locked ? '$capacity frames' : 'frames',
              style: TextStyle(
                fontSize: 12,
                color: locked
                    ? cs.outline.withValues(alpha: 0.5)
                    : selected
                        ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                        : cs.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
