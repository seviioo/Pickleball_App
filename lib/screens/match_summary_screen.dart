import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class MatchSummaryScreen extends StatefulWidget {
  final String? userName;
  final dynamic characterStyle;
  final double? aiDupr;
  final bool isVictory;
  final int playerScore;
  final int opponentScore;
  final String opponentName;
  final int coinsEarned;
  final int xpEarned;
  final int kitchenFaults;
  final int smashesLanded;
  final int longestRally;
  final bool leveledUp;
  final int newLevel;
  final bool isTournamentMatch;
  final int tournamentRound;

  const MatchSummaryScreen({
    Key? key,
    this.userName,
    this.characterStyle,
    this.aiDupr,
    this.isVictory = true,
    this.playerScore = 0,
    this.opponentScore = 0,
    this.opponentName = 'Opponent',
    this.coinsEarned = 150,
    this.xpEarned = 100,
    this.kitchenFaults = 0,
    this.smashesLanded = 0,
    this.longestRally = 0,
    this.leveledUp = false,
    this.newLevel = 1,
    this.isTournamentMatch = false,
    this.tournamentRound = 0,
  }) : super(key: key);

  @override
  State<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends State<MatchSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _counterController;
  late Animation<double> _counterAnimation;

  @override
  void initState() {
    super.initState();
    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _counterAnimation = CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutCubic,
    );

    _counterController.forward().then((_) {
      if (widget.leveledUp && mounted) {
        _showLevelUpOverlay();
      }
    });
  }

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  void _showLevelUpOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161920),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyanAccent, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.cyan,
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt,
                  color: Colors.cyanAccent,
                  size: 64,
                ),
                const SizedBox(height: 12),
                const Text(
                  'STREET REP UP!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You reached Level ${widget.newLevel}',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'New gear unlocked in the Black Market!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CLAIM REP',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWin =
        widget.playerScore >= widget.opponentScore && widget.isVictory;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _counterAnimation,
          builder: (context, child) {
            final double progress = _counterAnimation.value;
            final int displayCoins = (widget.coinsEarned * progress).round();
            final int displayXp = (widget.xpEarned * progress).round();

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildResultHeader(isWin),
                  const SizedBox(height: 20),
                  _buildScoreboardCard(),
                  const SizedBox(height: 24),
                  _buildRewardsContainer(displayCoins, displayXp),
                  const SizedBox(height: 24),
                  _buildMatchBreakdownCard(),
                  const Spacer(),
                  _buildContinueButton(isWin),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultHeader(bool isWin) {
    final Color headerColor = isWin ? Colors.amberAccent : Colors.redAccent;
    final String titleText = isWin ? 'VICTORY!' : 'DEFEATED';
    final IconData headerIcon = isWin ? Icons.emoji_events : Icons.heart_broken;

    return Column(
      children: [
        Icon(headerIcon, color: headerColor, size: 56),
        const SizedBox(height: 8),
        Text(
          titleText,
          style: TextStyle(
            color: headerColor,
            fontWeight: FontWeight.w900,
            fontSize: 34,
            letterSpacing: 2.5,
            shadows: [
              Shadow(
                color: headerColor.withOpacity(0.5),
                blurRadius: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreboardCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreColumn('YOU', widget.playerScore, Colors.greenAccent),
          Text(
            'VS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          _buildScoreColumn(
            widget.opponentName.toUpperCase(),
            widget.opponentScore,
            Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String label, int score, Color accent) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(
            color: accent,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsContainer(int displayCoins, int displayXp) {
    return Row(
      children: [
        Expanded(
          child: _buildRewardTile(
            label: 'COINS EARNED',
            value: '+$displayCoins',
            icon: Icons.monetization_on,
            color: Colors.amberAccent,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildRewardTile(
            label: 'STREET XP',
            value: '+$displayXp XP',
            icon: Icons.bolt,
            color: Colors.cyanAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MATCH BREAKDOWN',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          _buildStatRow('Smashes Landed', '${widget.smashesLanded}',
              Icons.flash_on, Colors.orangeAccent),
          const Divider(color: Colors.white10, height: 20),
          _buildStatRow('Longest Rally', '${widget.longestRally} hits',
              Icons.repeat, Colors.purpleAccent),
          const Divider(color: Colors.white10, height: 20),
          _buildStatRow('Kitchen Faults', '${widget.kitchenFaults}',
              Icons.warning_amber_rounded, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(bool isWin) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () async {
          if (isWin) {
            int coinsToAward = widget.coinsEarned;
            int xpToAward = widget.xpEarned;

            if (widget.isTournamentMatch) {
              final nextRound = widget.tournamentRound + 1;
              await StorageService.setTournamentRound(nextRound);
              if (widget.tournamentRound == 2) {
                coinsToAward += 1500;
                xpToAward += 500;
              }
            }

            final currentCoins = await StorageService.getCoins();
            final currentXp = await StorageService.getXp();
            final currentWins = await StorageService.getWins();

            await StorageService.setCoins(currentCoins + coinsToAward);
            await StorageService.setXp(currentXp + xpToAward);
            await StorageService.setWins(currentWins + 1);
          } else {
            final currentLosses = await StorageService.getLosses();
            await StorageService.setLosses(currentLosses + 1);
          }

          if (!mounted) return;
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isWin ? Colors.amberAccent : Colors.white24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Text(
          widget.isTournamentMatch && isWin
              ? (widget.tournamentRound == 2
                  ? 'CLAIM GRAND PRIZE'
                  : 'ADVANCE BRACKET')
              : 'RETURN TO STREETS',
          style: TextStyle(
            color: isWin ? Colors.black : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
