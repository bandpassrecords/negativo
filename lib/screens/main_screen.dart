import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/changelog_service.dart';
import '../widgets/whats_new_dialog.dart';
import 'changelog_screen.dart';
import 'rolls_screen.dart';
import 'albums_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (!isDevBuild) _showWhatsNew();
  }

  /// Once after an update: what changed since the version last opened.
  Future<void> _showWhatsNew() async {
    // Give a shortcut or widget tap on a cold start time to open its screen.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      // Something else is on screen (the camera, say): don't cover it, and
      // leave the update unseen so the next launch shows it.
      return;
    }
    final releases = await ChangelogService.takePendingChangelog(kAppVersion);
    if (!mounted) return;
    await showWhatsNewDialog(
      context,
      releases,
      onViewFullChangelog: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChangelogScreen()),
      ),
    );
  }

  Widget _buildTab() {
    switch (_index) {
      case 0:
        return RollsScreen(
          key: const ValueKey('rolls'),
          onGoToRewards: () => setState(() => _index = 2),
        );
      case 1:
        return const AlbumsScreen(key: ValueKey('albums'));
      case 2:
        return const ProgressScreen(key: ValueKey('progress'));
      case 3:
        return const SettingsScreen(key: ValueKey('settings'));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: _buildTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.camera_roll_outlined),
            selectedIcon: const Icon(Icons.camera_roll),
            label: l.navRolls,
          ),
          NavigationDestination(
            icon: const Icon(Icons.photo_library_outlined),
            selectedIcon: const Icon(Icons.photo_library),
            label: l.navAlbums,
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_outline_rounded),
            selectedIcon: const Icon(Icons.star_rounded),
            label: l.navRewards,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.navSettings,
          ),
        ],
      ),
    );
  }
}
