import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/film_roll.dart';
import '../services/film_service.dart';
import 'viewfinder_screen.dart';
import 'developed_gallery_screen.dart';

class FilmRollDetailScreen extends StatefulWidget {
  final FilmRoll filmRoll;

  const FilmRollDetailScreen({super.key, required this.filmRoll});

  @override
  State<FilmRollDetailScreen> createState() => _FilmRollDetailScreenState();
}

class _FilmRollDetailScreenState extends State<FilmRollDetailScreen> {
  late FilmRoll _roll;

  @override
  void initState() {
    super.initState();
    _roll = widget.filmRoll;
  }

  Future<void> _confirmDevelop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send for development?'),
        content: Text(
          _roll.isFull
              ? 'Your roll of ${_roll.capacity} frames is ready. '
                  'It will be developed in ${_formatHours(_roll.developmentDurationHours)}.'
              : 'You\'ve used ${_roll.exposureCount} of ${_roll.capacity} frames. '
                  'Rewind early and develop now?\n\n'
                  'Development takes ${_formatHours(_roll.developmentDurationHours)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Develop'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await FilmService.startDevelopment(_roll);
      setState(() {});
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this roll?'),
        content: Text(
          'All ${_roll.exposureCount} photo${_roll.exposureCount == 1 ? '' : 's'} '
          'will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await FilmService.deleteRoll(_roll);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr =
        DateFormat('MMMM d, yyyy').format(_roll.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(_roll.name),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            onPressed: _confirmDelete,
            tooltip: 'Delete roll',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBadge(cs),
            const SizedBox(height: 24),
            _buildInfoCard(dateStr),
            const SizedBox(height: 16),
            _buildFrameSection(cs),
            const SizedBox(height: 32),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ColorScheme cs) {
    final (label, color, textColor) = switch (_roll.status) {
      'active' => ('Active', cs.primaryContainer, cs.onPrimaryContainer),
      'developing' => (
          'Developing',
          cs.secondaryContainer,
          cs.onSecondaryContainer
        ),
      'developed' => (
          'Developed',
          cs.tertiaryContainer,
          cs.onTertiaryContainer
        ),
      _ => ('Unknown', cs.surfaceContainerLow, cs.onSurface),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String dateStr) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(label: 'Created', value: dateStr),
            const Divider(height: 20),
            _InfoRow(
                label: 'Capacity', value: '${_roll.capacity} frames'),
            if (_roll.status != 'active') ...[
              const Divider(height: 20),
              _InfoRow(
                  label: 'Exposed', value: '${_roll.exposureCount} frames'),
            ],
            if (_roll.developmentStartedAt != null) ...[
              const Divider(height: 20),
              _InfoRow(
                label: 'Sent to develop',
                value: DateFormat('MMM d, yyyy – HH:mm')
                    .format(_roll.developmentStartedAt!),
              ),
            ],
            if (_roll.developmentCompletesAt != null) ...[
              const Divider(height: 20),
              _InfoRow(
                label: _roll.isDevelopmentComplete
                    ? 'Developed on'
                    : 'Ready on',
                value: DateFormat('MMM d, yyyy – HH:mm')
                    .format(_roll.developmentCompletesAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFrameSection(ColorScheme cs) {
    if (_roll.status == 'active') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_roll.exposureCount} / ${_roll.capacity} frames',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_roll.capacity, (i) {
              final used = i < _roll.exposureCount;
              return Expanded(
                child: Container(
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: used
                        ? cs.primary
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            '${_roll.remainingFrames} frame${_roll.remainingFrames == 1 ? '' : 's'} remaining',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ],
      );
    }

    if (_roll.status == 'developing') {
      final remaining = _roll.remainingDevelopmentTime;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top_rounded,
                  color: cs.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                remaining != null && remaining.inSeconds > 0
                    ? _formatDuration(remaining)
                    : 'Almost ready…',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_roll.exposureCount} frames are being developed. '
            'You\'ll get a notification when they\'re ready.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActions() {
    switch (_roll.status) {
      case 'active':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ViewfinderScreen(filmRoll: _roll),
                    ),
                  );
                  setState(() {});
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Open Camera'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmDevelop,
                icon: const Icon(Icons.science_outlined),
                label: Text(_roll.isFull
                    ? 'Develop Roll'
                    : 'Rewind & Develop Early'),
              ),
            ),
          ],
        );

      case 'developed':
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DevelopedGalleryScreen(filmRoll: _roll),
                ),
              );
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('View Photos'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _formatHours(int hours) {
    if (hours < 24) return '$hours hours';
    final days = hours ~/ 24;
    return '$days day${days == 1 ? '' : 's'}';
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
