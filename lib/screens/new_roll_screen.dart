import 'package:flutter/material.dart';
import '../services/film_service.dart';

class NewRollScreen extends StatefulWidget {
  const NewRollScreen({super.key});

  @override
  State<NewRollScreen> createState() => _NewRollScreenState();
}

class _NewRollScreenState extends State<NewRollScreen> {
  int _selectedCapacity = 24;
  final _nameController = TextEditingController();
  bool _loading = false;

  final List<int> _capacities = [12, 24, 36];

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
    await FilmService.loadNewRoll(name, _selectedCapacity);
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
              children: _capacities.map((cap) {
                final selected = cap == _selectedCapacity;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _CapacityTile(
                      capacity: cap,
                      selected: selected,
                      onTap: () => setState(() => _selectedCapacity = cap),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
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
              autofocus: true,
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

class _CapacityTile extends StatelessWidget {
  final int capacity;
  final bool selected;
  final VoidCallback onTap;

  const _CapacityTile({
    required this.capacity,
    required this.selected,
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
          color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
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
              'frames',
              style: TextStyle(
                fontSize: 12,
                color: selected
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
