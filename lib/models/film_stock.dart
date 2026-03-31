import 'package:flutter/material.dart';

class FilmStock {
  final String id;
  final String name;
  final String brand;
  final String tagline;
  final String description;
  final Color accentColor;

  /// ScoringService feature key required to unlock this stock.
  /// null = always available (free).
  final String? unlockFeatureId;

  const FilmStock({
    required this.id,
    required this.name,
    required this.brand,
    required this.tagline,
    required this.description,
    required this.accentColor,
    this.unlockFeatureId,
  });

  // ── The four stocks ──────────────────────────────────────────────────────

  static const portra400 = FilmStock(
    id: 'portra400',
    name: 'Portra 400',
    brand: 'Kodak',
    tagline: 'Warm · Soft · Flattering',
    description:
        'The portrait photographer\'s choice. Natural skin tones, '
        'lifted shadows and a warm amber cast.',
    accentColor: Color(0xFFE8A44A),
    unlockFeatureId: null, // free
  );

  static const hp5 = FilmStock(
    id: 'hp5',
    name: 'HP5 Plus',
    brand: 'Ilford',
    tagline: 'B&W · Classic · Timeless',
    description:
        'The definitive black-and-white stock. Rich tonal range, '
        'classic contrast and very fine grain.',
    accentColor: Color(0xFF9E9E9E),
    unlockFeatureId: 'film_hp5',
  );

  static const ektar100 = FilmStock(
    id: 'ektar100',
    name: 'Ektar 100',
    brand: 'Kodak',
    tagline: 'Sharp · Vivid · Punchy',
    description:
        'World\'s finest grain colour negative. Ultra-vivid reds '
        'and punchy natural tones with striking contrast.',
    accentColor: Color(0xFFB71C1C),
    unlockFeatureId: 'film_ektar',
  );

  static const velvia50 = FilmStock(
    id: 'velvia50',
    name: 'Velvia 50',
    brand: 'Fujifilm',
    tagline: 'Vivid · Punchy · Saturated',
    description:
        'Legendary landscape film. Hyper-saturated colours, '
        'deep shadows and breathtaking contrast.',
    accentColor: Color(0xFF2E7D32),
    unlockFeatureId: 'film_velvia',
  );

  static const all = [portra400, hp5, ektar100, velvia50];

  static FilmStock? fromId(String? id) {
    if (id == null) return null;
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
