import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'equipment_screen.dart';
import 'match_setup_screen.dart';
import 'practice_tutorial_screen.dart';
import 'settings_screen.dart';
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
  int _userCoins = 0;
  int _userXp = 0;
  int _userWins = 0;
  int _userLosses = 0;
  bool _canClaimDaily = false;
  late String _currentUserName;

  @override
  void initState() {
    super.initState();
    _currentUserName = widget.userName;
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    final coins = await StorageService.getCoins();
    final xp = await StorageService.getXp();
    final wins = await StorageService.getWins();
    final losses = await StorageService.getLosses();
    final canClaim = await StorageService.canClaimDailyStash();

    if (mounted) {
      setState(() {
        _userCoins = coins;
        _userXp = xp;
        _userWins = wins;
        _userLosses = losses;
        _canClaimDaily = canClaim;
      });
    }
  }

  Future<void> _claimDailyStash() async {
    if (_canClaimDaily) {
      await StorageService.claimDailyStash();
      AudioService.playShotSfx('SMASH');
      await _refreshUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            'CLAIMED DAILY STASH: +150 COINS & +100 XP!',
            style:
                TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      body: StreetBackground(
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Player Header Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Kicker('STREET TAG',
                            icon: Icons.person_pin_rounded),
                        const SizedBox(height: 2),
                        Text(
                          _currentUserName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
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
                                color: AppColors.hairline, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on,
                                  color: AppColors.gold, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '$_userCoins',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.settings_rounded,
                              color: AppColors.textSecondary),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsScreen(
                                  currentUserName: _currentUserName,
                                  onUserNameChanged: (newName) {
                                    setState(() => _currentUserName = newName);
                                    StorageService.saveUserName(newName);
                                  },
                                  onResetProgress: () => _refreshUserData(),
                                ),
                              ),
                            );
                            _refreshUserData();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Street Stats & Daily Stash Card
                StreetCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECORD: $_userWins W - $_userLosses L',
                            style: const TextStyle(
                              color: AppColors.win,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'REP XP: $_userXp PTS',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canClaimDaily
                              ? AppColors.gold
                              : AppColors.surfaceRaised,
                          foregroundColor: _canClaimDaily
                              ? Colors.black
                              : AppColors.textFaint,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _canClaimDaily ? _claimDailyStash : null,
                        icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                        label: Text(
                          _canClaimDaily ? 'DAILY STASH' : 'CLAIMED',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Navigation Grid Buttons
                const Kicker('SELECT MODE'),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      PrimaryCTA(
                        label: 'QUICK MATCH',
                        icon: Icons.flash_on_rounded,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchSetupScreen(
                                userName: _currentUserName,
                                characterStyle: widget.characterStyle,
                              ),
                            ),
                          );
                          _refreshUserData();
                        },
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'UNDERGROUND BRACKET',
                        icon: Icons.emoji_events_rounded,
                        accent: AppColors.gold,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TournamentScreen(),
                            ),
                          );
                          _refreshUserData();
                        },
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'BLACK MARKET GEAR',
                        icon: Icons.shopping_bag_rounded,
                        accent: AppColors.redBright,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EquipmentScreen(
                                userName: _currentUserName,
                                characterStyle: widget.characterStyle,
                              ),
                            ),
                          );
                          _refreshUserData();
                        },
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'STREET ACADEMY (TUTORIAL)',
                        icon: Icons.school_rounded,
                        accent: Colors.cyanAccent,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PracticeTutorialScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
