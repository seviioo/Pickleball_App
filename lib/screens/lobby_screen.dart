import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'equipment_screen.dart';
import 'match_setup_screen.dart';
import 'practice_tutorial_screen.dart';
import 'tournament_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String userName;
  final CharacterStyleData characterStyle;

  const LobbyScreen({
    super.key,
    required this.userName,
    required this.characterStyle,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int userCoins = 0;
  PaddleData equippedPaddle = PaddleData.starter();
  bool isSoundOn = true;
  bool isHapticsOn = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final coins = await StorageService.getCoins();
    final paddle = await StorageService.getEquippedPaddle();
    final sound = await StorageService.getSoundEnabled();
    final haptics = await StorageService.getHapticsEnabled();

    if (mounted) {
      setState(() {
        userCoins = coins;
        equippedPaddle = paddle;
        isSoundOn = sound;
        isHapticsOn = haptics;
      });
    }
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.hairline, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings, color: AppColors.gold, size: 24),
                        SizedBox(width: 10),
                        Text('SETTINGS',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      activeThumbColor: AppColors.gold,
                      title: const Text('Sound FX',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      value: isSoundOn,
                      onChanged: (val) async {
                        setModalState(() => isSoundOn = val);
                        setState(() => isSoundOn = val);
                        AudioService.updateSettings(val, isHapticsOn);
                      },
                    ),
                    SwitchListTile(
                      activeThumbColor: AppColors.gold,
                      title: const Text('Haptic Vibration',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      value: isHapticsOn,
                      onChanged: (val) async {
                        setModalState(() => isHapticsOn = val);
                        setState(() => isHapticsOn = val);
                        AudioService.updateSettings(isSoundOn, val);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CLOSE',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      body: StreetBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.gold, width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          widget.characterStyle.outfitPrimary,
                                      child: const Icon(Icons.person,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Kicker('STREET TAG'),
                                      Text(widget.userName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.hairline,
                                          width: 1.5),
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
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.hairline,
                                          width: 1.5),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.settings,
                                          color: Colors.white, size: 20),
                                      onPressed: _openSettingsDialog,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Active Gear Spotlight
                          StreetCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceRaised,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.red, width: 1.5),
                                  ),
                                  child: const Icon(Icons.sports_tennis,
                                      color: AppColors.gold, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Kicker('EQUIPPED PADDLE'),
                                      Text(equippedPaddle.name,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right,
                                      color: AppColors.gold),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EquipmentScreen(
                                          userName: widget.userName,
                                          characterStyle: widget.characterStyle,
                                        ),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Quick Match Hero CTA
                          PrimaryCTA(
                            label: 'QUICK STREET MATCH',
                            icon: Icons.play_arrow_rounded,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MatchSetupScreen(
                                    userName: widget.userName,
                                    paddle: equippedPaddle,
                                    characterStyle: widget.characterStyle,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  label: 'TOURNAMENT',
                                  icon: Icons.emoji_events,
                                  accent: AppColors.redBright,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TournamentScreen(
                                          userName: widget.userName,
                                          paddle: equippedPaddle,
                                          characterStyle: widget.characterStyle,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SecondaryButton(
                                  label: 'BLACK MARKET',
                                  icon: Icons.shopping_bag,
                                  accent: AppColors.gold,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EquipmentScreen(
                                          userName: widget.userName,
                                          characterStyle: widget.characterStyle,
                                        ),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PracticeTutorialScreen(
                                      userName: widget.userName,
                                      paddle: equippedPaddle,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.school, size: 18),
                              label: const Text('PRACTICE COURT & DRILLS',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
