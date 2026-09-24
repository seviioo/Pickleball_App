import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class EquipmentScreen extends StatefulWidget {
  final String userName;
  final CharacterStyleData characterStyle;

  const EquipmentScreen({
    super.key,
    required this.userName,
    required this.characterStyle,
  });

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  int userCoins = 0;
  List<PaddleData> availablePaddles = [];
  PaddleData equippedPaddle = PaddleData.starter();
  PaddleData? selectedPaddle;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final coins = await StorageService.getCoins();
    final paddles = await StorageService.getPaddles();
    final equipped = await StorageService.getEquippedPaddle();

    if (mounted) {
      setState(() {
        userCoins = coins;
        availablePaddles = paddles;
        equippedPaddle = equipped;
        selectedPaddle ??= equipped;
      });
    }
  }

  Future<void> _equipPaddle(PaddleData paddle) async {
    await StorageService.setEquippedPaddle(paddle);
    AudioService.playShotSfx('DRIVE');
    await _loadStoreData();
  }

  Future<void> _buyPaddle(PaddleData paddle) async {
    if (userCoins >= paddle.price) {
      await StorageService.setCoins(userCoins - paddle.price);
      await StorageService.unlockPaddle(paddle.id);
      await StorageService.setEquippedPaddle(paddle);
      AudioService.playShotSfx('SMASH');
      await _loadStoreData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            '${paddle.name.toUpperCase()} UNLOCKED & EQUIPPED!',
            style: const TextStyle(
                color: AppColors.gold, fontWeight: FontWeight.w900),
          ),
        ),
      );
    } else {
      AudioService.playFaultSfx();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            'NOT ENOUGH COINS IN YOUR STASH!',
            style: TextStyle(
                color: AppColors.redBright, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeInspect = selectedPaddle ?? equippedPaddle;
    final bool isEquipped = activeInspect.id == equippedPaddle.id;

    return Scaffold(
      backgroundColor: AppColors.void_,
      extendBodyBehindAppBar: true,
      appBar: streetAppBar(
        'BLACK MARKET GEAR',
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairline, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: AppColors.gold, size: 18),
                    const SizedBox(width: 6),
                    Text('$userCoins',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: StreetBackground(
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inspection Hero Card with Rarity Accent
                StreetCard(
                  borderColor: activeInspect.rarity.color,
                  borderWidth: 1.8,
                  shadows: [
                    BoxShadow(
                      color: activeInspect.rarity.color.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceRaised,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: activeInspect.rarity.color,
                                  width: 1.8),
                            ),
                            child: Icon(Icons.sports_tennis_rounded,
                                color: activeInspect.rarity.color, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: activeInspect.rarity.color
                                            .withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: activeInspect.rarity.color,
                                            width: 1),
                                      ),
                                      child: Text(
                                        activeInspect.rarity.label,
                                        style: TextStyle(
                                          color: activeInspect.rarity.color,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    if (isEquipped) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'EQUIPPED',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activeInspect.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Animated Stat Comparison Fills
                      _buildStatRow('POWER', activeInspect.power,
                          equippedPaddle.power, AppColors.redBright),
                      const SizedBox(height: 10),
                      _buildStatRow('CONTROL', activeInspect.control,
                          equippedPaddle.control, const Color(0xFF38BDF8)),
                      const SizedBox(height: 10),
                      _buildStatRow('SPIN', activeInspect.spin,
                          equippedPaddle.spin, AppColors.gold),

                      const SizedBox(height: 20),

                      // CTA Button
                      if (activeInspect.isUnlocked)
                        PrimaryCTA(
                          label: isEquipped
                              ? 'CURRENTLY EQUIPPED'
                              : 'EQUIP PADDLE',
                          icon: isEquipped
                              ? Icons.check_circle_rounded
                              : Icons.flash_on_rounded,
                          foreground:
                              isEquipped ? AppColors.textFaint : Colors.black,
                          gradient: isEquipped
                              ? AppColors.cardSheen
                              : AppColors.goldButton,
                          onPressed: isEquipped
                              ? () {}
                              : () => _equipPaddle(activeInspect),
                          height: 50,
                        )
                      else
                        PrimaryCTA(
                          label: 'UNLOCK FOR ${activeInspect.price} COINS',
                          icon: Icons.lock_open_rounded,
                          gradient: userCoins >= activeInspect.price
                              ? AppColors.goldButton
                              : AppColors.redButton,
                          foreground: Colors.white,
                          onPressed: () => _buyPaddle(activeInspect),
                          height: 50,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Kicker('AVAILABLE BLACK MARKET INVENTORY'),
                const SizedBox(height: 10),

                // Inventory Grid / List
                Expanded(
                  child: ListView.separated(
                    itemCount: availablePaddles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final paddle = availablePaddles[index];
                      final bool isSelected = paddle.id == activeInspect.id;
                      final bool isPaddleEquipped =
                          paddle.id == equippedPaddle.id;

                      return GestureDetector(
                        onTap: () => setState(() => selectedPaddle = paddle),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? paddle.rarity.color.withOpacity(0.12)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? paddle.rarity.color
                                  : AppColors.hairline,
                              width: isSelected ? 1.8 : 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: isSelected
                                    ? paddle.rarity.color
                                    : AppColors.textFaint,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          paddle.name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? paddle.rarity.color
                                                : Colors.white,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PWR ${paddle.power}  ·  CTRL ${paddle.control}  ·  SPIN ${paddle.spin}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isPaddleEquipped)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'EQUIPPED',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
                                  ),
                                )
                              else if (!paddle.isUnlocked)
                                Row(
                                  children: [
                                    const Icon(Icons.monetization_on,
                                        color: AppColors.gold, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${paddle.price}',
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
      String label, int value, int equippedValue, Color color) {
    final int delta = value - equippedValue;
    final String deltaStr = delta > 0 ? '+$delta' : '$delta';
    final Color deltaColor = delta > 0
        ? AppColors.win
        : (delta < 0 ? AppColors.redBright : AppColors.textFaint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            Row(
              children: [
                if (delta != 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Text(
                      '($deltaStr)',
                      style: TextStyle(
                        color: deltaColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                Text(
                  '$value / 100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerLeft,
            widthFactor: (value / 100.0).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
