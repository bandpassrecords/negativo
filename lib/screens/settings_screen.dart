import 'package:flutter/material.dart';
import 'package:negativo/main.dart';
import '../l10n/app_localizations.dart';
import '../services/hive_service.dart';
import '../services/scoring_service.dart';
import '../models/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = HiveService.getSettings();
  }

  Future<void> _save() async {
    await HiveService.saveSettings(_settings);
    MyApp.updateTheme();
    MyApp.updateLanguage();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Appearance ──────────────────────────────────────────
          _SectionHeader(title: l.settingsAppearance),
          ListTile(
            title: Text(l.settingsTheme),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'light', icon: Icon(Icons.light_mode, size: 18)),
                ButtonSegment(value: 'system', icon: Icon(Icons.brightness_auto, size: 18)),
                ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode, size: 18)),
              ],
              selected: {_settings.themeMode},
              onSelectionChanged: (v) {
                setState(() => _settings.themeMode = v.first);
                _save();
              },
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          ListTile(
            title: Text(l.settingsLanguage),
            trailing: DropdownButton<String>(
              value: _settings.language,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'pt', child: Text('Português')),
                DropdownMenuItem(value: 'es', child: Text('Español')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                DropdownMenuItem(value: 'it', child: Text('Italiano')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _settings.language = v);
                _save();
              },
            ),
          ),

          const Divider(height: 32),

          // ── Film Development ─────────────────────────────────────
          _SectionHeader(title: l.settingsFilmDev),
          SwitchListTile(
            title: Text(l.settingsNotifyDev),
            subtitle: Text(l.settingsNotifyDevSub),
            value: _settings.developmentNotificationsEnabled,
            onChanged: (v) {
              setState(() => _settings.developmentNotificationsEnabled = v);
              _save();
            },
          ),

          const Divider(height: 32),

          // ── Debug ────────────────────────────────────────────────
          const _SectionHeader(title: 'Debug'),
          ListTile(
            title: const Text('Grant 50 000 points'),
            subtitle: const Text('Temporary testing shortcut'),
            trailing: FilledButton.tonal(
              onPressed: () async {
                await ScoringService.addPoints(50000);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('50 000 points added!')),
                  );
                }
              },
              child: const Text('Grant'),
            ),
          ),

          const Divider(height: 32),

          // ── Statistics ───────────────────────────────────────────
          _SectionHeader(title: l.settingsStatistics),
          _StatTile(
            label: l.settingsRollsDeveloped,
            value: '${HiveService.getTotalDevelopedRolls()}',
          ),
          _StatTile(
            label: l.settingsTotalPhotos,
            value: '${HiveService.getTotalExposures()}',
          ),
          _StatTile(
            label: l.settingsTotalRolls,
            value: '${HiveService.getTotalRolls()}',
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
