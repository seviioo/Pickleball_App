import 'package:flutter/material.dart';

// ==========================================
// CHARACTER ANIMATION & STYLE MODELS
// ==========================================
enum CharacterAnimState {
  idle,
  running,
  swinging,
  celebrating,
  serving,
  drive,
  smash,
  slice,
  lob,
}

class CharacterStyleData {
  final String id;
  final String name;
  final Color outfitPrimary;
  final Color outfitSecondary;
  final Color skinTone;
  final double speedMultiplier;
  final int price;
  final bool isUnlocked;

  const CharacterStyleData({
    required this.id,
    required this.name,
    required this.outfitPrimary,
    required this.outfitSecondary,
    required this.skinTone,
    this.speedMultiplier = 1.0,
    required this.price,
    this.isUnlocked = false,
  });

  Color get primaryColor => outfitPrimary;
  Color get secondaryColor => outfitSecondary;
}

final List<CharacterStyleData> kCharacterStyles = [
  const CharacterStyleData(
    id: 'rookie_blue',
    name: 'Rookie Blue',
    outfitPrimary: Color(0xFF2563EB),
    outfitSecondary: Color(0xFF1D4ED8),
    skinTone: Color(0xFFFDBA74),
    speedMultiplier: 1.0,
    price: 0,
    isUnlocked: true,
  ),
  const CharacterStyleData(
    id: 'urban_fire',
    name: 'Urban Fire',
    outfitPrimary: Color(0xFFDC2626),
    outfitSecondary: Color(0xFF991B1B),
    skinTone: Color(0xFFFED7AA),
    speedMultiplier: 1.05,
    price: 500,
    isUnlocked: false,
  ),
  const CharacterStyleData(
    id: 'neon_strike',
    name: 'Neon Strike',
    outfitPrimary: Color(0xFF10B981),
    outfitSecondary: Color(0xFF047857),
    skinTone: Color(0xFFFDE68A),
    speedMultiplier: 1.1,
    price: 1000,
    isUnlocked: false,
  ),
];

// ==========================================
// PADDLE RARITY ENUM & STYLING
// ==========================================
enum PaddleRarity {
  common,
  uncommon,
  epic,
  legendary,
  mythic,
  divine,
  eternal;

  String get label {
    switch (this) {
      case PaddleRarity.common:
        return 'COMMON';
      case PaddleRarity.uncommon:
        return 'UNCOMMON';
      case PaddleRarity.epic:
        return 'EPIC';
      case PaddleRarity.legendary:
        return 'LEGENDARY';
      case PaddleRarity.mythic:
        return 'MYTHIC';
      case PaddleRarity.divine:
        return 'DIVINE';
      case PaddleRarity.eternal:
        return 'ETERNAL';
    }
  }

  Color get color {
    switch (this) {
      case PaddleRarity.common:
        return const Color(0xFF9CA3AF);
      case PaddleRarity.uncommon:
        return const Color(0xFF22C55E);
      case PaddleRarity.epic:
        return const Color(0xFFA855F7);
      case PaddleRarity.legendary:
        return const Color(0xFFF59E0B);
      case PaddleRarity.mythic:
        return const Color(0xFFEF4444);
      case PaddleRarity.divine:
        return const Color(0xFF38BDF8);
      case PaddleRarity.eternal:
        return const Color(0xFFEC4899);
    }
  }
}

// ==========================================
// PADDLE DATA MODEL
// ==========================================
class PaddleData {
  final String id;
  final String name;
  final int power;
  final int control;
  final int spin;
  final int price;
  final bool isUnlocked;
  final PaddleRarity rarity;
  final Color faceColor;
  final Color accentColor;
  final String patternStyle;

  PaddleData({
    required this.id,
    required this.name,
    required this.power,
    required this.control,
    required this.spin,
    required this.price,
    required this.isUnlocked,
    required this.rarity,
    Color? faceColor,
    Color? accentColor,
    this.patternStyle = 'plain',
  })  : faceColor = faceColor ?? rarity.color,
        accentColor = accentColor ?? Colors.white;

  factory PaddleData.starter() {
    return PaddleData(
      id: 'starter_paddle',
      name: 'Common Paddle I',
      power: 40,
      control: 60,
      spin: 30,
      price: 0,
      isUnlocked: true,
      rarity: PaddleRarity.common,
      faceColor: const Color(0xFF4B5563),
      accentColor: const Color(0xFF9CA3AF),
      patternStyle: 'stripes',
    );
  }

  PaddleData copyWith({
    String? id,
    String? name,
    int? power,
    int? control,
    int? spin,
    int? price,
    bool? isUnlocked,
    PaddleRarity? rarity,
    Color? faceColor,
    Color? accentColor,
    String? patternStyle,
  }) {
    return PaddleData(
      id: id ?? this.id,
      name: name ?? this.name,
      power: power ?? this.power,
      control: control ?? this.control,
      spin: spin ?? this.spin,
      price: price ?? this.price,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      rarity: rarity ?? this.rarity,
      faceColor: faceColor ?? this.faceColor,
      accentColor: accentColor ?? this.accentColor,
      patternStyle: patternStyle ?? this.patternStyle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'power': power,
      'control': control,
      'spin': spin,
      'price': price,
      'isUnlocked': isUnlocked,
      'rarity': rarity.name,
      'faceColor': faceColor.value,
      'accentColor': accentColor.value,
      'patternStyle': patternStyle,
    };
  }

  factory PaddleData.fromJson(Map<String, dynamic> json) {
    return PaddleData(
      id: json['id'] ?? 'starter_paddle',
      name: json['name'] ?? 'Common Paddle I',
      power: json['power'] ?? 40,
      control: json['control'] ?? 60,
      spin: json['spin'] ?? 30,
      price: json['price'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? true,
      rarity: PaddleRarity.values.firstWhere(
        (r) => r.name == json['rarity'],
        orElse: () => PaddleRarity.common,
      ),
      faceColor: json['faceColor'] != null ? Color(json['faceColor']) : null,
      accentColor:
          json['accentColor'] != null ? Color(json['accentColor']) : null,
      patternStyle: json['patternStyle'] ?? 'plain',
    );
  }
}

// ==========================================
// DEFAULT FICTIONAL PADDLES CATALOG
// ==========================================
final List<PaddleData> kDefaultPaddles = [
  PaddleData(
    id: 'starter_paddle',
    name: 'Common Paddle I',
    power: 40,
    control: 60,
    spin: 30,
    price: 0,
    isUnlocked: true,
    rarity: PaddleRarity.common,
    faceColor: const Color(0xFF4B5563),
    accentColor: const Color(0xFF9CA3AF),
    patternStyle: 'stripes',
  ),
  PaddleData(
    id: 'street_striker',
    name: 'Street Striker',
    power: 71,
    control: 72,
    spin: 49,
    price: 250,
    isUnlocked: false,
    rarity: PaddleRarity.common,
    faceColor: const Color(0xFF374151),
    accentColor: const Color(0xFFF59E0B),
    patternStyle: 'lightning',
  ),
  PaddleData(
    id: 'alley_driver',
    name: 'Alley Driver',
    power: 74,
    control: 70,
    spin: 55,
    price: 300,
    isUnlocked: false,
    rarity: PaddleRarity.common,
    faceColor: const Color(0xFF1F2937),
    accentColor: const Color(0xFF10B981),
    patternStyle: 'cross',
  ),
  PaddleData(
    id: 'forest_edge',
    name: 'Forest Edge',
    power: 79,
    control: 83,
    spin: 78,
    price: 450,
    isUnlocked: false,
    rarity: PaddleRarity.uncommon,
    faceColor: const Color(0xFF15803D),
    accentColor: const Color(0xFF86EFAC),
    patternStyle: 'ring',
  ),
  PaddleData(
    id: 'emerald_blitz',
    name: 'Emerald Blitz',
    power: 82,
    control: 80,
    spin: 81,
    price: 600,
    isUnlocked: false,
    rarity: PaddleRarity.uncommon,
    faceColor: const Color(0xFF047857),
    accentColor: const Color(0xFF34D399),
    patternStyle: 'lightning',
  ),
  PaddleData(
    id: 'violet_shadow',
    name: 'Violet Shadow',
    power: 86,
    control: 88,
    spin: 89,
    price: 900,
    isUnlocked: false,
    rarity: PaddleRarity.epic,
    faceColor: const Color(0xFF6B21A8),
    accentColor: const Color(0xFFE9D5FF),
    patternStyle: 'ring',
  ),
  PaddleData(
    id: 'shadow_spin',
    name: 'Shadow Spin',
    power: 88,
    control: 85,
    spin: 92,
    price: 1200,
    isUnlocked: false,
    rarity: PaddleRarity.epic,
    faceColor: const Color(0xFF581C87),
    accentColor: const Color(0xFFC084FC),
    patternStyle: 'swirl',
  ),
  PaddleData(
    id: 'golden_smash',
    name: 'Golden Smash',
    power: 92,
    control: 90,
    spin: 91,
    price: 1800,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
    faceColor: const Color(0xFFB45309),
    accentColor: const Color(0xFFFDE047),
    patternStyle: 'crown',
  ),
  PaddleData(
    id: 'solar_edge',
    name: 'Solar Edge',
    power: 90,
    control: 94,
    spin: 93,
    price: 2500,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
    faceColor: const Color(0xFFD97706),
    accentColor: const Color(0xFFFEF08A),
    patternStyle: 'sunburst',
  ),
  PaddleData(
    id: 'crimson_fury',
    name: 'Crimson Fury',
    power: 95,
    control: 92,
    spin: 96,
    price: 4000,
    isUnlocked: false,
    rarity: PaddleRarity.mythic,
    faceColor: const Color(0xFF991B1B),
    accentColor: const Color(0xFFFCA5A5),
    patternStyle: 'flame',
  ),
  PaddleData(
    id: 'celestial_wave',
    name: 'Celestial Wave',
    power: 97,
    control: 96,
    spin: 97,
    price: 6500,
    isUnlocked: false,
    rarity: PaddleRarity.divine,
    faceColor: const Color(0xFF0369A1),
    accentColor: const Color(0xFFBAE6FD),
    patternStyle: 'wave',
  ),
  PaddleData(
    id: 'eternal_bloom',
    name: 'Eternal Bloom',
    power: 99,
    control: 98,
    spin: 99,
    price: 10000,
    isUnlocked: false,
    rarity: PaddleRarity.eternal,
    faceColor: const Color(0xFFBE185D),
    accentColor: const Color(0xFFFBCFE8),
    patternStyle: 'star',
  ),
];
