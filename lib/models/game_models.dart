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
        return 'BLACK MARKET ELITE';
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
  final String imagePath;
  final int power;
  final int control;
  final int spin;
  final int price;
  final bool isUnlocked;
  final PaddleRarity rarity;

  PaddleData({
    required this.id,
    required this.name,
    required this.imagePath,
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
      imagePath: 'assets/paddles/starter_paddle.png',
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
    String? imagePath,
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
      imagePath: imagePath ?? this.imagePath,
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
  // --- STARTER GEAR ---
  PaddleData(
    id: 'starter_paddle',
    name: 'Street Woodie',
    imagePath: 'assets/paddles/starter_paddle.png',
    power: 40,
    control: 60,
    spin: 30,
    price: 0,
    isUnlocked: true,
    rarity: PaddleRarity.common,
  ),

  // --- COMMON TIER ---
  PaddleData(
    id: 'onix_z5',
    name: 'Onix Graphite Z5',
    imagePath: 'assets/paddles/onix_z5.png',
    power: 71,
    control: 72,
    spin: 49,
    price: 250,
    isUnlocked: false,
    rarity: PaddleRarity.common,
  ),
  PaddleData(
    id: 'head_radical_pro',
    name: 'HEAD Radical Pro',
    imagePath: 'assets/paddles/head_radical_pro.png',
    power: 69,
    control: 76,
    spin: 66,
    price: 300,
    isUnlocked: false,
    rarity: PaddleRarity.common,
  ),
  PaddleData(
    id: 'paddletek_ts5',
    name: 'Paddletek Bantam TS-5',
    imagePath: 'assets/paddles/paddletek_ts5.png',
    power: 73,
    control: 68,
    spin: 59,
    price: 350,
    isUnlocked: false,
    rarity: PaddleRarity.common,
  ),
  PaddleData(
    id: 'franklin_ben_johns',
    name: 'Franklin Ben Johns 16mm',
    imagePath: 'assets/paddles/franklin_ben_johns.png',
    power: 69,
    control: 71,
    spin: 66,
    price: 400,
    isUnlocked: false,
    rarity: PaddleRarity.common,
  ),
  PaddleData(
    id: 'crbn_genesis_1',
    name: 'CRBN TruFoam Genesis 1',
    imagePath: 'assets/paddles/crbn_genesis_1.png',
    power: 74,
    control: 56,
    spin: 89,
    price: 450,
    isUnlocked: false,
    rarity: PaddleRarity.common,
  ),

  // --- RARE TIER ---
  PaddleData(
    id: 'vatic_prism_flash',
    name: 'Vatic Pro Prism Flash 16mm',
    imagePath: 'assets/paddles/vatic_prism_flash.png',
    power: 65,
    control: 76,
    spin: 83,
    price: 600,
    isUnlocked: false,
    rarity: PaddleRarity.rare,
  ),
  PaddleData(
    id: 'engage_pursuit_maxx',
    name: 'Engage Pursuit MAXX MX 6.0',
    imagePath: 'assets/paddles/engage_pursuit_maxx.png',
    power: 70,
    control: 75,
    spin: 66,
    price: 750,
    isUnlocked: false,
    rarity: PaddleRarity.rare,
  ),
  PaddleData(
    id: 'engage_pursuit_graphite',
    name: 'Engage Pursuit MX 6.0',
    imagePath: 'assets/paddles/engage_pursuit_graphite.png',
    power: 69,
    control: 74,
    spin: 69,
    price: 800,
    isUnlocked: false,
    rarity: PaddleRarity.rare,
  ),
  PaddleData(
    id: 'crbn_genesis_2',
    name: 'CRBN TruFoam Genesis 2',
    imagePath: 'assets/paddles/crbn_genesis_2.png',
    power: 71,
    control: 72,
    spin: 86,
    price: 900,
    isUnlocked: false,
    rarity: PaddleRarity.rare,
  ),
  PaddleData(
    id: 'crbn_waves_1',
    name: 'CRBN TruFoam Waves 1',
    imagePath: 'assets/paddles/crbn_waves_1.png',
    power: 78,
    control: 59,
    spin: 86,
    price: 950,
    isUnlocked: false,
    rarity: PaddleRarity.rare,
  ),
  PaddleData(
    id: 'ronbus_r1_nova',
    name: 'Ronbus R1 Nova',
    imagePath: 'assets/paddles/ronbus_r1_nova.png',
    power: 72,
    control: 65,
    spin: 86,
    price: 1100,
    isUnlocked: false,
    rarity: PaddleRarity.rare,
  ),
  PaddleData(
    id: 'gearbox_cx14e',
    name: 'Gearbox CX14E Ultimate Power',
    imagePath: 'assets/paddles/gearbox_cx14e.png',
    power: 81,
    control: 62,
    spin: 80,
    price: 1250,
    isUnlocked: false,
    rarity: PaddleRarity.rare,
  ),
  PaddleData(
    id: 'selkirk_luxx_invikta',
    name: 'Selkirk LUXX Control Air',
    imagePath: 'assets/paddles/selkirk_luxx_invikta.png',
    power: 59,
    control: 79,
    spin: 86,
    price: 1400,
    isUnlocked: false,
    rarity: PaddleRarity.rare,
  ),

  // --- EPIC / LEGENDARY TIER ---
  PaddleData(
    id: 'joola_perseus_pro_4',
    name: 'JOOLA Perseus Pro IV 16mm',
    imagePath: 'assets/paddles/joola_perseus_pro_4.png',
    power: 80,
    control: 65,
    spin: 84,
    price: 1800,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),
  PaddleData(
    id: 'joola_perseus_pro_5',
    name: 'JOOLA Perseus Pro V 16mm',
    imagePath: 'assets/paddles/joola_perseus_pro_5.png',
    power: 77,
    control: 67,
    spin: 90,
    price: 2200,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),
  PaddleData(
    id: 'honolulu_j6cr',
    name: 'Honolulu J6CR Crystal Blue',
    imagePath: 'assets/paddles/honolulu_j6cr.png',
    power: 78,
    control: 67,
    spin: 95,
    price: 2400,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),
  PaddleData(
    id: 'honolulu_j6nf',
    name: 'Honolulu J6NF Endurance',
    imagePath: 'assets/paddles/honolulu_j6nf.png',
    power: 77,
    control: 71,
    spin: 90,
    price: 2500,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),
  PaddleData(
    id: 'selkirk_power_air',
    name: 'Selkirk Vanguard Power Air',
    imagePath: 'assets/paddles/selkirk_power_air.png',
    power: 81,
    control: 56,
    spin: 90,
    price: 2800,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),
  PaddleData(
    id: 'sixzero_black_opal',
    name: 'Six Zero Black Opal',
    imagePath: 'assets/paddles/sixzero_black_opal.png',
    power: 85,
    control: 59,
    spin: 88,
    price: 3200,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),
  PaddleData(
    id: 'sixzero_coral_pro_elongated',
    name: 'Six Zero Coral Pro Elongated',
    imagePath: 'assets/paddles/sixzero_coral_pro_elongated.png',
    power: 77,
    control: 67,
    spin: 92,
    price: 3500,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),
  PaddleData(
    id: 'sixzero_coral_pro_widebody',
    name: 'Six Zero Coral Pro Widebody',
    imagePath: 'assets/paddles/sixzero_coral_pro_widebody.png',
    power: 71,
    control: 82,
    spin: 92,
    price: 3800,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),

  // --- BLACK MARKET EXCLUSIVES ---
  PaddleData(
    id: 'diadem_vice',
    name: 'Diadem VICE (EVA Concept)',
    imagePath: 'assets/paddles/diadem_vice.png',
    power: 70,
    control: 71,
    spin: 76,
    price: 4500,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),
  PaddleData(
    id: 'prokennex_black_ace',
    name: 'ProKennex Kinetic Black Ace',
    imagePath: 'assets/paddles/prokennex_black_ace.png',
    power: 86,
    control: 56,
    spin: 83,
    price: 5200,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),
  PaddleData(
    id: 'joola_mod_ta15',
    name: 'JOOLA Perseus Mod TA-15 (Banned)',
    imagePath: 'assets/paddles/joola_mod_ta15.png',
    power: 86,
    control: 61,
    spin: 90,
    price: 6000,
    isUnlocked: false,
    rarity: PaddleRarity.legendary,
  ),
];
