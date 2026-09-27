import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/film_roll.dart';
import '../screens/developed_gallery_screen.dart';
import '../screens/reveal_gallery_screen.dart';
import '../services/hive_service.dart';
import '../services/roll_widget_service.dart';

/// Asks whether to open [roll] now that it has just been developed (DEV NOW,
/// or the instant development boost). "Open" goes where the albums tab
/// would: the reveal while there are frames to develop, else the gallery.
///
/// Completes once the dialog is dismissed or the opened roll is closed, so
/// the caller can refresh.
Future<void> showRollDevelopedDialog(
    BuildContext context, FilmRoll roll) async {
  final l = AppLocalizations.of(context)!;
  final open = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.photo_library_outlined),
      title: Text(l.developedDialogTitle),
      content: Text(l.developedDialogBody(roll.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.developedDialogLater),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.developedDialogOpen),
        ),
      ],
    ),
  );
  if (open != true || !context.mounted) return;

  final reveal = needsReveal(
    roll,
    HiveService.getExposuresForRoll(roll.id),
    revealEnabled: HiveService.getSettings().albumRevealEnabled,
  );
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => reveal
          ? RevealGalleryScreen(filmRoll: roll)
          : DevelopedGalleryScreen(filmRoll: roll),
    ),
  );
}
