import 'package:flutter/material.dart';
import '../models/film_roll.dart';
import '../services/scoring_service.dart';
import '../services/film_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<FilmRoll> _developingRolls = [];

  @override
  void initState() {
    super.initState();
    _developingRolls = HiveService.getFilmRollsByStatus('developing');
  }

  Future<void> _reload() async {
    await FilmService.checkDevelopmentCompletions();
    setState(() {
      _developingRolls = HiveService.getFilmRollsByStatus('developing');
    });
  }

  Future<void> _tryUnlock(String feature) async {
    final cost = ScoringService.unlockCosts[feature]!;
    if (ScoringService.points < cost) {
      _showSnack('Not enough points (need $cost, have ${ScoringService.points})');
      return;
    }
    final ok = await ScoringService.unlock(feature);
    if (ok && mounted) {
      setState(() {});
      _showSnack('🎉 Unlocked: ${ScoringService.unlockNames[feature]}!');
    }
  }

  Future<void> _speedDev(FilmRoll roll, bool instant) async {
    final cost = instant ? ScoringService.costSpeedInstant : ScoringService.costSpeedHalf;
    if (ScoringService.points < cost) {
      _showSnack('Not enough points (need $cost)');
      return;
    }
    final ok = await ScoringService.spendPoints(cost);
    if (!ok) return;

    if (instant) {
      roll.status = 'developed';
      await HiveService.saveFilmRoll(roll);
      await NotificationService.cancelDevelopmentNotification(roll.id);
    } else {
      // Shift start time back by half the remaining duration
      final remaining = roll.remainingDevelopmentTime;
      if (remaining != null && remaining.inMinutes > 0) {
        final shiftBy = Duration(minutes: remaining.inMinutes ~/ 2);
        roll.developmentStartedAt =
            roll.developmentStartedAt!.subtract(shiftBy);
        await HiveService.saveFilmRoll(roll);
      }
    }
    await _reload();
    if (mounted) {
      _showSnack(instant ? '⚡ Development complete!' : '⏩ Cut remaining time in half!');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pts = ScoringService.points;
    final lifetime = ScoringService.lifetimePoints;
    final next = ScoringService.nextLockedFeature;
    final progress = ScoringService.progressToNext();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // ── Points header ───────────────────────────────────────────────
            Card(
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '$pts',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: cs.onPrimaryContainer,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'available points',
                      style: TextStyle(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (next != null) ...[
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            cs.onPrimaryContainer.withValues(alpha: 0.15),
                        color: cs.onPrimaryContainer,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progress * 100).toInt()}% toward ${ScoringService.unlockNames[next]}',
                        style: TextStyle(
                          color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ] else
                      Text(
                        '🏆 All features unlocked!',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '$lifetime pts earned all-time',
                      style: TextStyle(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── How to earn ─────────────────────────────────────────────────
            _SectionHeader('HOW TO EARN'),
            const SizedBox(height: 8),
            _EarnTile(icon: Icons.camera_alt, label: 'Take a photo', pts: '+${ScoringService.ptsPerPhoto}'),
            _EarnTile(icon: Icons.camera_roll, label: 'Use every frame on a roll', pts: '+${ScoringService.ptsFullRoll}'),
            _EarnTile(icon: Icons.science_outlined, label: 'Send roll to develop', pts: '+${ScoringService.ptsStartDev}'),
            _EarnTile(icon: Icons.check_circle_outline, label: 'Roll fully developed', pts: '+${ScoringService.ptsCompleteDev}'),
            _EarnTile(icon: Icons.timer_outlined, label: 'Wind at exactly 0.8 s', pts: 'up to +25'),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Wind precision: ±0.05 s = 25 pts · ±0.15 s = 15 pts · ±0.30 s = 8 pts · ±0.50 s = 3 pts',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.outline),
              ),
            ),

            const SizedBox(height: 24),

            // ── Permanent unlocks ───────────────────────────────────────────
            _SectionHeader('UPGRADES'),
            const SizedBox(height: 8),
            ...ScoringService.featureOrder.map((f) => _UnlockCard(
                  feature: f,
                  points: pts,
                  onUnlock: () => _tryUnlock(f),
                )),

            // ── Development boost ────────────────────────────────────────────
            if (_developingRolls.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionHeader('DEVELOPMENT BOOST'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Spend points to speed up a developing roll.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline),
                ),
              ),
              const SizedBox(height: 8),
              ..._developingRolls.map((roll) => _DevBoostCard(
                    roll: roll,
                    points: pts,
                    onSpeedHalf: () => _speedDev(roll, false),
                    onInstant: () => _speedDev(roll, true),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _EarnTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String pts;
  const _EarnTile({required this.icon, required this.label, required this.pts});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.outline),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium)),
          Text(
            pts,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final String feature;
  final int points;
  final VoidCallback onUnlock;
  const _UnlockCard(
      {required this.feature, required this.points, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unlocked = ScoringService.isUnlocked(feature);
    final cost = ScoringService.unlockCosts[feature]!;
    final canAfford = points >= cost;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: unlocked
            ? cs.secondaryContainer
            : cs.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                unlocked ? Icons.lock_open_rounded : Icons.lock_outline,
                color: unlocked ? cs.onSecondaryContainer : cs.outline,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ScoringService.unlockNames[feature]!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: unlocked
                                ? cs.onSecondaryContainer
                                : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ScoringService.unlockDescriptions[feature]!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: unlocked
                                ? cs.onSecondaryContainer.withValues(alpha: 0.7)
                                : cs.outline,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (unlocked)
                Icon(Icons.check_circle, color: cs.onSecondaryContainer)
              else
                FilledButton(
                  onPressed: canAfford ? onUnlock : null,
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('$cost pts',
                      style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevBoostCard extends StatelessWidget {
  final FilmRoll roll;
  final int points;
  final VoidCallback onSpeedHalf;
  final VoidCallback onInstant;
  const _DevBoostCard({
    required this.roll,
    required this.points,
    required this.onSpeedHalf,
    required this.onInstant,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = roll.remainingDevelopmentTime;
    final canHalf    = points >= ScoringService.costSpeedHalf;
    final canInstant = points >= ScoringService.costSpeedInstant;

    String timeLabel = 'Almost ready';
    if (remaining != null && remaining.inSeconds > 0) {
      if (remaining.inDays >= 1) {
        timeLabel = '${remaining.inDays}d ${remaining.inHours % 24}h left';
      } else if (remaining.inHours >= 1) {
        timeLabel = '${remaining.inHours}h ${remaining.inMinutes % 60}m left';
      } else {
        timeLabel = '${remaining.inMinutes}m left';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: cs.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      roll.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(timeLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.outline)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canHalf ? onSpeedHalf : null,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                      child: Text(
                          '⏩ Half time\n${ScoringService.costSpeedHalf} pts',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: canInstant ? onInstant : null,
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                      child: Text(
                          '⚡ Instant\n${ScoringService.costSpeedInstant} pts',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
