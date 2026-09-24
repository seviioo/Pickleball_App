import 'package:flutter/material.dart';

enum PaddleRarity { common, rare, epic, legendary }

extension PaddleRarityX on PaddleRarity {
  String get label {
    switch (this) {
      case PaddleRarity.common:
        return 'COMMON';
      case PaddleRarity.rare:
        return 'RARE';
      case PaddleRarity.epic:
        return 'EPIC';
      case PaddleRarity.legendary:
        return 'LEGENDARY';
    }
  }

  Color get color {
    switch (this) {
      case PaddleRarity.common:
        return const Color(0xFFA1A1AA);
      case PaddleRarity.rare:
        return const Color(0xFF38BDF8);
      case PaddleRarity.epic:
        return const Color(0xFFA855F7);
      case PaddleRarity.legendary:
        return const Color(0xFFFACC15);
    }
  }
}

class PaddleData {
  final String id;
  final String name;
  final int power;
  final int control;
  final int spin;
  final int price;
  final bool isUnlocked;

  PaddleData({
    required this.id,
    required this.name,
    required this.power,
    required this.control,
    required this.spin,
    required this.price,
    this.isUnlocked = false,
  });

  PaddleRarity get rarity {
    if (price >= 1000) return PaddleRarity.legendary;
    if (price >= 500) return PaddleRarity.epic;
    if (price >= 200) return PaddleRarity.rare;
    return PaddleRarity.common;
  }

  Color get accentColor => rarity.color;

  factory PaddleData.starter() {
    return PaddleData(
      id: 'starter_wooden',
      name: 'Wooden Starter 10mm',
      power: 45,
      control: 60,
      spin: 40,
      price: 0,
      isUnlocked: true,
    );
  }
}

class CharacterStyleData {
  final Color outfitPrimary;
  final double speedMultiplier;
  final double powerMultiplier;

  CharacterStyleData({
    required this.outfitPrimary,
    this.speedMultiplier = 1.0,
    this.powerMultiplier = 1.0,
  });

  factory CharacterStyleData.defaultStyle() {
    return CharacterStyleData(
      outfitPrimary: const Color(0xFFDC2626),
      speedMultiplier: 1.0,
      powerMultiplier: 1.0,
    );
  }
}

final List<CharacterStyleData> kCharacterStyles = [
  CharacterStyleData.defaultStyle(),
];
