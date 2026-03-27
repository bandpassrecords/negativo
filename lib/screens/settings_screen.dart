import 'package:flutter/material.dart';
import 'package:retro1/main.dart';
import '../services/hive_service.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Appearance ──────────────────────────────────────────
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            title: const Text('Theme'),
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
            title: const Text('Language'),
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
          const _SectionHeader(title: 'Film Development'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'How long should it take to develop your film?',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 24, label: Text('1 day')),
                ButtonSegment(value: 48, label: Text('2 days')),
                ButtonSegment(value: 72, label: Text('3 days')),
                ButtonSegment(value: 168, label: Text('1 week')),
              ],
              selected: {_settings.developmentDurationHours},
              onSelectionChanged: (v) {
                setState(() => _settings.developmentDurationHours = v.first);
                _save();
              },
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Notify when developed'),
            subtitle: const Text('Get a notification when your film is ready'),
            value: _settings.developmentNotificationsEnabled,
            onChanged: (v) {
              setState(() => _settings.developmentNotificationsEnabled = v);
              _save();
            },
          ),

          const Divider(height: 32),

          // ── Statistics ───────────────────────────────────────────
          const _SectionHeader(title: 'Statistics'),
          _StatTile(
            label: 'Rolls developed',
            value: '${HiveService.getTotalDevelopedRolls()}',
          ),
          _StatTile(
            label: 'Total photos taken',
            value: '${HiveService.getTotalExposures()}',
          ),
          _StatTile(
            label: 'Total rolls',
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
