import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
