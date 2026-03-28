import 'package:shared_preferences/shared_preferences.dart';

class ScoringService {
  // SharedPreferences keys
  static const _keyPoints   = 'neg_pts';
  static const _keyLifetime = 'neg_pts_life';
  static const _keyUnlocked = 'neg_unlocked';

  // ── Feature identifiers ───────────────────────────────────────────────────
  static const String roll24        = 'roll_24';
  static const String roll36        = 'roll_36';
  static const String slot2         = 'slot_2';
  static const String slotUnlimited = 'slot_unlimited';

  // ── Earning ───────────────────────────────────────────────────────────────
  static const int ptsPerPhoto    = 5;
  static const int ptsFullRoll    = 30;  // bonus when every frame is used
  static const int ptsStartDev    = 15;
  static const int ptsCompleteDev = 60;

  /// Precision bonus for winding — target is exactly 0.8 s.
  static const double windTarget = 0.8;
  static int windBonus(double seconds) {
    final d = (seconds - windTarget).abs();
    if (d <= 0.05) return 25; // ★ Perfect
    if (d <= 0.15) return 15; // ✓ Great
    if (d <= 0.30) return  8; // Good
    if (d <= 0.50) return  3; // OK
    return 0;
  }

  static String windBonusLabel(int pts) {
    if (pts >= 25) return '★ Perfect wind!';
    if (pts >= 15) return '✓ Great wind';
    if (pts >=  8) return 'Good wind';
    if (pts >=  3) return 'OK wind';
    return '';
  }

  // ── Permanent unlock costs ────────────────────────────────────────────────
  static const List<String> featureOrder = [roll24, roll36, slot2, slotUnlimited];

  static const Map<String, int> unlockCosts = {
    roll24:        150,
    roll36:        400,
    slot2:         900,
    slotUnlimited: 2500,
  };

  static const Map<String, String> unlockNames = {
    roll24:        '24-frame rolls',
    roll36:        '36-frame rolls',
    slot2:         'Load 2 rolls at once',
    slotUnlimited: 'Unlimited rolls',
  };

  static const Map<String, String> unlockDescriptions = {
    roll24:        'Unlock 24-exposure film rolls for longer sessions.',
    roll36:        'Unlock the photographer\'s standard — 36 exposures.',
    slot2:         'Keep two rolls loaded simultaneously.',
    slotUnlimited: 'The ultimate upgrade — load as many rolls as you want.',
  };

  // ── Consumable costs (spent per action) ───────────────────────────────────
  static const int costSpeedHalf    = 75;   // halve remaining development time
  static const int costSpeedInstant = 200;  // complete development immediately

  // ── Persistence ───────────────────────────────────────────────────────────
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static int get points         => _prefs?.getInt(_keyPoints)   ?? 0;
  static int get lifetimePoints => _prefs?.getInt(_keyLifetime) ?? 0;
  static List<String> get unlocked =>
      List<String>.from(_prefs?.getStringList(_keyUnlocked) ?? []);

  static bool isUnlocked(String feature) => unlocked.contains(feature);

  static Future<void> addPoints(int amount) async {
    await _prefs!.setInt(_keyPoints,   points + amount);
    await _prefs!.setInt(_keyLifetime, lifetimePoints + amount);
  }

  /// Returns false if insufficient points.
  static Future<bool> spendPoints(int amount) async {
    if (points < amount) return false;
    await _prefs!.setInt(_keyPoints, points - amount);
    return true;
  }

  /// Permanently unlock a feature; returns false if can't afford.
  static Future<bool> unlock(String feature) async {
    if (isUnlocked(feature)) return true;
    final cost = unlockCosts[feature];
    if (cost == null) return false;
    if (!await spendPoints(cost)) return false;
    await _prefs!.setStringList(_keyUnlocked, [...unlocked, feature]);
    return true;
  }

  // ── Derived state ─────────────────────────────────────────────────────────

  static int get maxActiveSlots {
    if (isUnlocked(slotUnlimited)) return 99;
    if (isUnlocked(slot2)) return 2;
    return 1;
  }

  static List<int> get availableCapacities => [
    12,
    if (isUnlocked(roll24)) 24,
    if (isUnlocked(roll36)) 36,
  ];

  /// Progress toward the next locked feature (0.0 – 1.0).
  static double progressToNext() {
    for (final f in featureOrder) {
      if (!isUnlocked(f)) {
        final cost = unlockCosts[f]!;
        return (points / cost).clamp(0.0, 1.0);
      }
    }
    return 1.0;
  }

  static String? get nextLockedFeature {
    for (final f in featureOrder) {
      if (!isUnlocked(f)) return f;
    }
    return null;
  }
}
