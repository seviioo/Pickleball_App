import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'lobby_screen.dart';

class MatchSummaryScreen extends StatefulWidget {
  final String userName;
  final CharacterStyleData characterStyle;
  final int playerScore;
  final int opponentScore;
  final double aiDupr;

  const MatchSummaryScreen({
    super.key,
    required this.userName,
    required this.characterStyle,
    required this.playerScore,
    required this.opponentScore,
    required this.aiDupr,
  });

  @override
  State<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends State<MatchSummaryScreen> {
  int coinsEarned = 0;
  int xpEarned = 0;
  int totalCoins = 0;
  int totalXp = 0;
  bool isWin = false;

  @override
  void initState() {
    super.initState();
    isWin = widget.playerScore > widget.opponentScore;

    double duprMultiplier = widget.aiDupr / 3.0;
    int baseCoins = isWin ? 150 : 40;
    int scoreBonus = widget.playerScore * 10;

    coinsEarned = ((baseCoins + scoreBonus) * duprMultiplier).round();
    xpEarned = ((isWin ? 250 : 80) * duprMultiplier).round();

    _saveRewards();
  }

  Future<void> _saveRewards() async {
    await StorageService.addCoins(coinsEarned);
    await StorageService.addXp(xpEarned);
    await StorageService.recordMatchResult(isWin: isWin);

    final updatedCoins = await StorageService.getCoins();
    final updatedXp = await StorageService.getXp();

    if (mounted) {
      setState(() {
        totalCoins = updatedCoins;
        totalXp = updatedXp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = isWin ? AppColors.gold : AppColors.redBright;

    return Scaffold(
      backgroundColor: AppColors.void_,
      body: StreetBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreetCard(
                  padding: const EdgeInsets.all(28),
                  borderColor: accent,
                  borderWidth: 1.8,
                  shadows: [
                    BoxShadow(
                        color: accent.withOpacity(0.28),
                        blurRadius: 32,
                        offset: const Offset(0, 12)),
                  ],
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isWin
                              ? AppColors.goldButton
                              : AppColors.redButton,
                          boxShadow: [
                            BoxShadow(
                                color: accent.withOpacity(0.4), blurRadius: 26),
                          ],
                        ),
                        child: Icon(
                          isWin
                              ? Icons.emoji_events_rounded
                              : Icons.sentiment_dissatisfied_rounded,
                          color: isWin ? Colors.black : Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        isWin ? 'STREET VICTORY' : 'MATCH DEFEAT',
                        style: TextStyle(
                          color: accent,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.playerScore} — ${widget.opponentScore}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _rewardColumn(
                              'STASH BOUNTY', '+$coinsEarned', 'COINS',
                              icon: Icons.monetization_on_rounded,
                              color: AppColors.gold),
                          Container(
                              width: 1, height: 42, color: AppColors.hairline),
                          _rewardColumn('STREET REP', '+$xpEarned', 'XP',
                              icon: Icons.bolt_rounded,
                              color: AppColors.textPrimary),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryCTA(
                  label: 'RETURN TO LOBBY',
                  icon: Icons.home_rounded,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LobbyScreen(
                          userName: widget.userName,
                          characterStyle: widget.characterStyle,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rewardColumn(String label, String value, String unit,
      {required IconData icon, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: AppColors.textFaint,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6)),
        const SizedBox(height: 4),
        Text('$value $unit',
            style: TextStyle(
                color: color, fontSize: 17, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
