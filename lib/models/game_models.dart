import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// ENUMS
// ---------------------------------------------------------------------------

enum CharacterAnimState {
  idle,
  smash,
  slice,
  lob,
  serving,
  drive,
  walkingUp,
  walkingDown,
  walkingLeft,
  walkingRight,
  run,
  hit,
  serve,
}

enum OrbType {
  doublePoints,
  shrinkOpponent,
  shrinkRay,
  speedBoost,
}

enum PaddleRarity {
  common,
  rare,
  legendary,
}

extension PaddleRarityExtension on PaddleRarity {
  String get label {
    switch (this) {
      case PaddleRarity.common:
        return 'STREET COMMON';
      case PaddleRarity.rare:
        return 'PRO RARE';
      case PaddleRarity.legendary:
        return 'LEGENDARY ELITE';
    }
  }

  Color get color {
    switch (this) {
      case PaddleRarity.common:
        return const Color(0xFFA1A1AA);
      case PaddleRarity.rare:
        return const Color(0xFF38BDF8);
      case PaddleRarity.legendary:
        return const Color(0xFFFACC15);
    }
  }
}

// ---------------------------------------------------------------------------
// PADDLE DATA MODEL
// ---------------------------------------------------------------------------

class PaddleData {
  final String id;
  final String name;
  final int power;
  final int control;
  final int spin;
  final int price;
  final bool isUnlocked;
  final PaddleRarity rarity;

  PaddleData({
    required this.id,
    required this.name,
    required this.power,
    required this.control,
    required this.spin,
    required this.price,
    required this.isUnlocked,
    required this.rarity,
  });

  factory PaddleData.starter() {
    return PaddleData(
      id: 'starter_paddle',
      name: 'Street Woodie',
      power: 40,
      control: 60,
      spin: 30,
      price: 0,
      isUnlocked: true,
      rarity: PaddleRarity.common,
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
    );
  }
}

// ---------------------------------------------------------------------------
// CHARACTER STYLE MODEL
// ---------------------------------------------------------------------------

class CharacterStyleData {
  final String name;
  final Color outfitPrimary;
  final Color outfitSecondary;
  final double speedMultiplier;

  CharacterStyleData({
    required this.name,
    required this.outfitPrimary,
    required this.outfitSecondary,
    this.speedMultiplier = 1.0,
  });
}

// ---------------------------------------------------------------------------
// DEFAULT GAME CONSTANTS
// ---------------------------------------------------------------------------

final List<CharacterStyleData> kCharacterStyles = [
  CharacterStyleData(
    name: 'Neon Rebel',
    outfitPrimary: const Color(0xFFFACC15),
    outfitSecondary: const Color(0xFFDC2626),
    speedMultiplier: 1.0,
  ),
  CharacterStyleData(
    name: 'Cyber Dinker',
    outfitPrimary: const Color(0xFF38BDF8),
    outfitSecondary: const Color(0xFF818CF8),
    speedMultiplier: 1.1,
  ),
];

final List<PaddleData> kDefaultPaddles = [
  PaddleData(
    id: 'starter_paddle',
    name: 'Street Woodie',
    power: 40,
    control: 60,
    spin: 30,
    price: 0,
    isUnlocked: true,
    rarity: PaddleRarity.common,
  ),
  PaddleData(
    id: 'carbon_pro',
    name: 'Carbon Viper',
    power: 70,
    control: 75,
    spin: 80,
    price: 350,
    isUnlocked: false,
    rarity: PaddleRarity.rare,
  ),
  PaddleData(
    id: 'titanium_edge',
    name: 'Kitchen Dominator',
    power: 90,
    control: 85,
    spin: 95,
    price: 800,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),
];
