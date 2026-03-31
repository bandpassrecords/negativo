import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context)!;
    final duration = _formatHours(_roll.developmentDurationHours, l);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.detailSendToDevelop),
        content: Text(
          _roll.isFull
              ? l.detailSendFullBody(_roll.capacity, duration)
              : l.detailSendPartialBody(_roll.exposureCount, _roll.capacity, duration),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.detailCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.detailDevelop),
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
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.detailDeleteTitle),
        content: Text(l.detailDeleteBody(_roll.exposureCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.detailCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.detailDelete),
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
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('MMMM d, yyyy').format(_roll.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(_roll.name),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            onPressed: _confirmDelete,
            tooltip: l.detailDeleteTooltip,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBadge(cs, l),
            const SizedBox(height: 24),
            _buildInfoCard(dateStr, l),
            const SizedBox(height: 16),
            _buildFrameSection(cs, l),
            const SizedBox(height: 32),
            _buildActions(l),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ColorScheme cs, AppLocalizations l) {
    final (label, color, textColor) = switch (_roll.status) {
      'active' => (l.detailStatusActive, cs.primaryContainer, cs.onPrimaryContainer),
      'developing' => (l.detailStatusDeveloping, cs.secondaryContainer, cs.onSecondaryContainer),
      'developed' => (l.detailStatusDeveloped, cs.tertiaryContainer, cs.onTertiaryContainer),
      _ => (l.detailStatusUnknown, cs.surfaceContainerLow, cs.onSurface),
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

  Widget _buildInfoCard(String dateStr, AppLocalizations l) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(label: l.detailInfoCreated, value: dateStr),
            const Divider(height: 20),
            _InfoRow(
                label: l.detailInfoCapacity,
                value: l.detailInfoFramesCount(_roll.capacity)),
            if (_roll.status != 'active') ...[
              const Divider(height: 20),
              _InfoRow(
                  label: l.detailInfoExposed,
                  value: l.detailInfoFramesCount(_roll.exposureCount)),
            ],
            if (_roll.developmentStartedAt != null) ...[
              const Divider(height: 20),
              _InfoRow(
                label: l.detailInfoSentToDevelop,
                value: DateFormat('MMM d, yyyy – HH:mm')
                    .format(_roll.developmentStartedAt!),
              ),
            ],
            if (_roll.developmentCompletesAt != null) ...[
              const Divider(height: 20),
              _InfoRow(
                label: _roll.isDevelopmentComplete
                    ? l.detailInfoDevelopedOn
                    : l.detailInfoReadyOn,
                value: DateFormat('MMM d, yyyy – HH:mm')
                    .format(_roll.developmentCompletesAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFrameSection(ColorScheme cs, AppLocalizations l) {
    if (_roll.status == 'active') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.detailFramesUsedOf(_roll.exposureCount, _roll.capacity),
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
                    color: used ? cs.primary : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            l.detailFramesRemaining(_roll.remainingFrames),
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
                    ? _formatDuration(remaining, l)
                    : l.detailAlmostReady,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.detailDevelopingBody(_roll.exposureCount),
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

  Widget _buildActions(AppLocalizations l) {
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
                      builder: (_) => ViewfinderScreen(filmRoll: _roll),
                    ),
                  );
                  setState(() {});
                },
                icon: const Icon(Icons.camera_alt),
                label: Text(l.detailOpenCamera),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmDevelop,
                icon: const Icon(Icons.science_outlined),
                label: Text(_roll.isFull
                    ? l.detailDevelopRoll
                    : l.detailRewindDevelop),
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
                  builder: (_) => DevelopedGalleryScreen(filmRoll: _roll),
                ),
              );
            },
            icon: const Icon(Icons.photo_library),
            label: Text(l.detailViewPhotos),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _formatHours(int hours, AppLocalizations l) {
    if (hours < 24) return l.detailDurationHours(hours);
    final days = hours ~/ 24;
    return l.detailDurationDays(days);
  }

  String _formatDuration(Duration d, AppLocalizations l) {
    if (d.inDays >= 1) {
      return l.rollsDaysHoursRemaining(d.inDays, d.inHours % 24);
    } else if (d.inHours >= 1) {
      return l.rollsHoursMinutesRemaining(d.inHours, d.inMinutes % 60);
    } else {
      return l.rollsMinutesRemaining(d.inMinutes);
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
