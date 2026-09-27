import 'package:flutter/widgets.dart';

/// Navigation from outside any screen — a home-screen shortcut or widget tap.
///
/// On a cold start the tap arrives before the first screen exists, so an
/// action that can't run yet is queued and run once the navigator is up
/// (main.dart calls [flush] after the first frame).
class AppNavigator {
  AppNavigator._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final _pending = <void Function(NavigatorState)>[];

  /// Runs [action] now if the app can navigate, otherwise as soon as it can.
  static void run(void Function(NavigatorState navigator) action) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      action(nav);
      return;
    }
    _pending.add(action);
    WidgetsBinding.instance.addPostFrameCallback((_) => flush());
  }

  /// Runs whatever was queued before the navigator existed.
  static void flush() {
    final nav = navigatorKey.currentState;
    if (nav == null || _pending.isEmpty) return;
    final actions = List.of(_pending);
    _pending.clear();
    for (final action in actions) {
      action(nav);
    }
  }
}
