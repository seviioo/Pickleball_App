import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/storage_service.dart';
import 'court_gameplay_screen.dart';

class TournamentRival {
  final String name;
  final String nickname;
  final String title;
  final double dupr;
  final Color themeColor;
  final IconData avatarIcon;

  const TournamentRival({
    required this.name,
    required this.nickname,
    required this.title,
    required this.dupr,
    required this.themeColor,
    required this.avatarIcon,
  });
}

const List<TournamentRival> kTournamentRivals = [
  TournamentRival(
    name: 'Rook Vance',
    nickname: 'Dink Master',
    title: 'Quarterfinal Boss',
    dupr: 2.5,
    themeColor: Colors.cyanAccent,
    avatarIcon: Icons.sports_tennis,
  ),
  TournamentRival(
    name: 'Maya Lin',
    nickname: 'Kitchen Queen',
    title: 'Semifinal Boss',
    dupr: 4.0,
    themeColor: Colors.purpleAccent,
    avatarIcon: Icons.bolt,
  ),
  TournamentRival(
    name: 'Jax Steele',
    nickname: 'Spin Boss',
    title: 'Finals Legend',
    dupr: 5.5,
    themeColor: Colors.orangeAccent,
    avatarIcon: Icons.local_fire_department,
  ),
];

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({Key? key}) : super(key: key);

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _currentRound = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadRoundProgress();
  }

  Future<void> _loadRoundProgress() async {
    final round = await StorageService.getTournamentRound();
    if (mounted) {
      setState(() => _currentRound = round);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'UNDERGROUND BRACKET',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final pulseValue = _pulseController.value;
          return Column(
            children: [
              _buildPrizePoolSpotlight(pulseValue),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: BracketRailsPainter(
                            currentRound: _currentRound,
                            pulseProgress: pulseValue,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            List.generate(kTournamentRivals.length, (index) {
                          return _buildRivalCard(
                            rival: kTournamentRivals[index],
                            roundIndex: index,
                            pulseValue: pulseValue,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              _buildStartMatchButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrizePoolSpotlight(double pulseValue) {
    final glowOpacity = 0.3 + (pulseValue * 0.4);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1A08), Color(0xFF140F07), Color(0xFF2A1A08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amberAccent.withOpacity(0.6 + (pulseValue * 0.4)),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(glowOpacity),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withOpacity(0.15),
              border: Border.all(color: Colors.amberAccent, width: 2),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.amberAccent,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      'GRAND PRIZE PURSE',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.workspace_premium,
                        color: Colors.amber, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '1,500 COINS + RARE STREET PADDLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+500 Street Rep XP upon bracket clearance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRivalCard({
    required TournamentRival rival,
    required int roundIndex,
    required double pulseValue,
  }) {
    final bool isDefeated = _currentRound > roundIndex;
    final bool isCurrent = _currentRound == roundIndex;
    final bool isLocked = _currentRound < roundIndex;
    Color cardBorder = isCurrent
        ? rival.themeColor
        : (isDefeated ? Colors.greenAccent.withOpacity(0.5) : Colors.white10);
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFF16181D) : const Color(0xFF1F232C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? rival.themeColor.withOpacity(0.7 + (pulseValue * 0.3))
              : cardBorder,
          width: isCurrent ? 2.5 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: rival.themeColor.withOpacity(0.3 * pulseValue),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isLocked
                    ? Colors.grey.shade900
                    : rival.themeColor.withOpacity(0.2),
                child: Icon(
                  isLocked ? Icons.lock : rival.avatarIcon,
                  color: isLocked ? Colors.grey : rival.themeColor,
                  size: 28,
                ),
              ),
              if (isDefeated)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 32,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${rival.name} "${rival.nickname}"',
                  style: TextStyle(
                    color: isLocked ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rival.title,
                  style: TextStyle(
                    color: isLocked ? Colors.white24 : rival.themeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrent
                  ? rival.themeColor.withOpacity(0.2)
                  : Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent ? rival.themeColor : Colors.white10,
              ),
            ),
            child: Text(
              'DUPR ${rival.dupr.toStringAsFixed(1)}',
              style: TextStyle(
                color: isCurrent ? rival.themeColor : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartMatchButton() {
    final bool bracketFinished = _currentRound >= kTournamentRivals.length;
    final currentRival =
        bracketFinished ? null : kTournamentRivals[_currentRound];

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF14161C),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: bracketFinished
                ? () async {
                    await StorageService.resetTournament();
                    _loadRoundProgress();
                  }
                : () async {
                    final equippedPaddle =
                        await StorageService.getEquippedPaddle();
                    if (!context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourtGameplayScreen(
                          userName: 'Player',
                          paddle: equippedPaddle,
                          characterStyle: kCharacterStyles[0],
                          targetScore: 11,
                          aiDupr: currentRival!.dupr,
                          isTournamentMatch: true,
                          tournamentRound: _currentRound,
                        ),
                      ),
                    );
                    _loadRoundProgress();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: bracketFinished
                  ? Colors.amber
                  : (currentRival?.themeColor ?? Colors.amberAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Text(
              bracketFinished
                  ? 'RESET BRACKET FOR NEW RUN'
                  : 'ENTER ${currentRival?.title.toUpperCase()}',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BracketRailsPainter extends CustomPainter {
  final int currentRound;
  final double pulseProgress;

  BracketRailsPainter({
    required this.currentRound,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cardHeight = 90.0;
    final double verticalGap = (size.height - (cardHeight * 3)) / 2;
    final double startX = 40.0;
    final double y1 = cardHeight / 2;
    final double y2 = y1 + cardHeight + verticalGap;
    final double y3 = y2 + cardHeight + verticalGap;

    _drawRailSegment(
      canvas: canvas,
      start: Offset(startX, y1 + 24),
      end: Offset(startX, y2 - 24),
      isActive: currentRound >= 1,
      isPulsing: currentRound == 0,
    );

    _drawRailSegment(
      canvas: canvas,
      start: Offset(startX, y2 + 24),
      end: Offset(startX, y3 - 24),
      isActive: currentRound >= 2,
      isPulsing: currentRound == 1,
    );
  }

  void _drawRailSegment({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required bool isActive,
    required bool isPulsing,
  }) {
    final basePaint = Paint()
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    if (isActive) {
      basePaint.color = Colors.greenAccent;
      canvas.drawLine(start, end, basePaint);
    } else if (isPulsing) {
      basePaint.color = Color.lerp(
        Colors.amberAccent.withOpacity(0.3),
        Colors.amberAccent,
        pulseProgress,
      )!;
      basePaint.strokeWidth = 4.0;

      final glowPaint = Paint()
        ..color = Colors.amberAccent.withOpacity(0.4 * pulseProgress)
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawLine(start, end, glowPaint);
      canvas.drawLine(start, end, basePaint);
    } else {
      basePaint.color = Colors.white10;
      canvas.drawLine(start, end, basePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BracketRailsPainter oldDelegate) {
    return oldDelegate.currentRound != currentRound ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}
