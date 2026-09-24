import 'package:flutter/material.dart';

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

  Color get accentColor => const Color(0xFFFACC15);

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
