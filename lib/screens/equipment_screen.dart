import 'package:flutter/material.dart';
import '../models/game_models.dart';
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
      });
    }
  }

  Future<void> _equipPaddle(PaddleData paddle) async {
    await StorageService.setEquippedPaddle(paddle);
    await _loadStoreData();
  }

  Future<void> _buyPaddle(PaddleData paddle) async {
    if (userCoins >= paddle.price) {
      await StorageService.setCoins(userCoins - paddle.price);
      await StorageService.unlockPaddle(paddle.id);
      await StorageService.setEquippedPaddle(paddle);
      await _loadStoreData();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: AppColors.gold, size: 17),
                    const SizedBox(width: 5),
                    Text('$userCoins',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreetBackground(
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: availablePaddles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final paddle = availablePaddles[index];
              final bool isEquipped = paddle.id == equippedPaddle.id;
              final bool canAfford = userCoins >= paddle.price;

              return StreetCard(
                padding: EdgeInsets.zero,
                borderColor: isEquipped ? AppColors.gold : AppColors.hairline,
                borderWidth: isEquipped ? 1.6 : 1.2,
                shadows: isEquipped
                    ? [
                        BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 6)),
                      ]
                    : null,
                child: Column(
                  children: [
                    // Header strip
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        gradient: isEquipped
                            ? LinearGradient(
                                colors: [
                                  AppColors.gold.withValues(alpha: 0.14),
                                  Colors.transparent,
                                ],
                              )
                            : null,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceRaised,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: isEquipped
                                    ? AppColors.gold
                                    : AppColors.redDeep,
                                width: 1.4,
                              ),
                            ),
                            child: Icon(Icons.sports_tennis_rounded,
                                color: isEquipped
                                    ? AppColors.gold
                                    : AppColors.textSecondary,
                                size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(paddle.name,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900)),
                          ),
                          if (isEquipped)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: AppColors.goldButton,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('EQUIPPED',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9.5,
                                      letterSpacing: 0.4)),
                            )
                          else if (!paddle.isUnlocked)
                            const Icon(Icons.lock_rounded,
                                color: AppColors.textFaint, size: 18),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        children: [
                          _buildStatBar(
                              'POWER', paddle.power, AppColors.redBright),
                          const SizedBox(height: 8),
                          _buildStatBar(
                              'CONTROL', paddle.control, AppColors.gold),
                          const SizedBox(height: 8),
                          _buildStatBar(
                              'SPIN', paddle.spin, const Color(0xFF38BDF8)),
                          if (!isEquipped) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: paddle.isUnlocked
                                  ? PrimaryCTA(
                                      label: 'EQUIP PADDLE',
                                      icon: Icons.check_circle_outline_rounded,
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFF27272A),
                                        Color(0xFF18181B)
                                      ]),
                                      glowColor: Colors.black,
                                      foreground: AppColors.textPrimary,
                                      height: 46,
                                      onPressed: () => _equipPaddle(paddle),
                                    )
                                  : PrimaryCTA(
                                      label: canAfford
                                          ? 'BUY FOR ${paddle.price} COINS'
                                          : 'NEED ${paddle.price - userCoins} MORE COINS',
                                      icon: Icons.lock_open_rounded,
                                      gradient: canAfford
                                          ? AppColors.redButton
                                          : const LinearGradient(colors: [
                                              Color(0xFF3F3F46),
                                              Color(0xFF27272A),
                                            ]),
                                      glowColor: AppColors.red,
                                      foreground: Colors.white,
                                      height: 46,
                                      onPressed: canAfford
                                          ? () => _buyPaddle(paddle)
                                          : () {},
                                    ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
            width: 58,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100.0,
              backgroundColor: AppColors.hairline,
              color: color,
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 24,
          child: Text('$value',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
