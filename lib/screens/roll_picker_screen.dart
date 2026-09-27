import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/film_roll.dart';
import '../services/camera_shortcut_service.dart';
import '../services/hive_service.dart';
import 'viewfinder_screen.dart';

/// "Which roll?" — opened from the home-screen "Choose a roll" shortcut when
/// more than one roll is loaded. Picking one goes straight to its viewfinder,
/// replacing this screen, so backing out of the camera lands in the app.
class RollPickerScreen extends StatelessWidget {
  const RollPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rolls = shootableRolls(HiveService.getAllFilmRolls());

    return Scaffold(
      appBar: AppBar(title: Text(l.shortcutChooseRollTitle)),
      body: rolls.isEmpty
          ? Center(child: Text(l.rollsEmpty))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: rolls.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _RollTile(roll: rolls[i]),
            ),
    );
  }
}

class _RollTile extends StatelessWidget {
  const _RollTile({required this.roll});

  final FilmRoll roll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.camera_roll_outlined),
      title: Text(roll.name),
      subtitle: Text(l.rollsFramesUsed(roll.exposureCount, roll.capacity)),
      trailing: const Icon(Icons.photo_camera_outlined),
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ViewfinderScreen(filmRoll: roll)),
      ),
    );
  }
}
