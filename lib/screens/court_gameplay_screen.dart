import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/pickleball_game.dart';
import '../models/game_models.dart' hide CharacterAnimState, OrbType;
import '../painters/perspective_court_painter.dart';
import 'lobby_screen.dart';
import 'match_summary_screen.dart';

class CourtGameplayScreen extends StatefulWidget {
  final String userName;
  final PaddleData paddle;
  final CharacterStyleData characterStyle;
  final int targetScore;
  final double aiDupr;
  final bool isTournamentMatch;
  final int tournamentRound;

  const CourtGameplayScreen({
    super.key,
    required this.userName,
    required this.paddle,
    required this.characterStyle,
    required this.targetScore,
    required this.aiDupr,
    this.isTournamentMatch = false,
    this.tournamentRound = 0,
  });

  @override
  State<CourtGameplayScreen> createState() => _CourtGameplayScreenState();
}

class _CourtGameplayScreenState extends State<CourtGameplayScreen> {
  late PickleballGame game;
  int playerScore = 0;
  int opponentScore = 0;
  bool isPlayerServing = true;
  String matchStatus = 'STREET SERVE READY';
  bool isGameOver = false;
  bool _hasShownGameOverModal = false;
  double ultimateGauge = 0.0;
  bool isUltimateActive = false;
  double ballX = 0.0;
  double ballY = 0.85;
  double ballHeight = 0.4;
  double playerX = 0.0;
  double playerY = 0.85;
  double opponentX = 0.0;
  double opponentY = -0.85;
  double? orbX;
  double? orbY;
  OrbType? orbType;
  bool isDoublePointsActive = false;
  bool isAiShrunk = false;
  String? timingFeedback;
  double? aimTargetX;
  double? aimTargetY;
  bool isAiming = false;
  String selectedShotType = 'DRIVE';
  CharacterAnimState playerAnimState = CharacterAnimState.idle;
  CharacterAnimState aiAnimState = CharacterAnimState.idle;
  int playerFrame = 0;
  int aiFrame = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    game = PickleballGame(
      userName: widget.userName,
      paddle: widget.paddle,
      characterStyle: widget.characterStyle,
      targetScore: widget.targetScore,
      aiDupr: widget.aiDupr,
      onStateUpdate: ({
        required int playerScore,
        required int opponentScore,
        required bool isPlayerServing,
        required String matchStatus,
        required bool isGameOver,
        required double ballX,
        required double ballY,
        required double ballHeight,
        required double playerX,
        required double playerY,
        required double opponentX,
        required double opponentY,
        required double ultimateGauge,
        required bool isUltimateActive,
        required double? orbX,
        required double? orbY,
        required OrbType? orbType,
        required bool isDoublePointsActive,
        required bool isAiShrunk,
        String? timingFeedback,
        required CharacterAnimState playerAnimState,
        required CharacterAnimState aiAnimState,
        required int playerFrame,
        required int aiFrame,
        double? aimTargetX,
        double? aimTargetY,
        required bool isAiming,
      }) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              this.playerScore = playerScore;
              this.opponentScore = opponentScore;
              this.isPlayerServing = isPlayerServing;
              this.matchStatus = matchStatus;
              this.isGameOver = isGameOver;
              this.ballX = ballX;
              this.ballY = ballY;
              this.ballHeight = ballHeight;
              this.playerX = playerX;
              this.playerY = playerY;
              this.opponentX = opponentX;
              this.opponentY = opponentY;
              this.ultimateGauge = ultimateGauge;
              this.isUltimateActive = isUltimateActive;
              this.orbX = orbX;
              this.orbY = orbY;
              this.orbType = orbType;
              this.isDoublePointsActive = isDoublePointsActive;
              this.isAiShrunk = isAiShrunk;
              this.timingFeedback = timingFeedback;
              this.playerAnimState = playerAnimState;
              this.aiAnimState = aiAnimState;
              this.playerFrame = playerFrame;
              this.aiFrame = aiFrame;
              this.aimTargetX = aimTargetX;
              this.aimTargetY = aimTargetY;
              this.isAiming = isAiming;
            });
            if (isGameOver && !_hasShownGameOverModal) {
              _hasShownGameOverModal = true;
              _showGameOverDialog();
            }
          }
        });
      },
    );
  }

  void _showGameOverDialog() {
    final bool isWin = playerScore > opponentScore;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isWin ? const Color(0xFFFACC15) : const Color(0xFFDC2626),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  color:
                      isWin ? const Color(0xFFFACC15) : const Color(0xFFDC2626),
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  isWin ? 'VICTORY!' : 'DEFEAT!',
                  style: TextStyle(
                    color: isWin
                        ? const Color(0xFFFACC15)
                        : const Color(0xFFDC2626),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'FINAL SCORE: $playerScore - $opponentScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isWin
                          ? const Color(0xFFFACC15)
                          : const Color(0xFFDC2626),
                      foregroundColor: isWin ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToSummary();
                    },
                    child: const Text(
                      'CLAIM MATCH REWARDS',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
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

  void _openPauseMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF18181B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pause_circle_filled,
                    color: Color(0xFFFACC15), size: 56),
                const SizedBox(height: 12),
                const Text('MATCH PAUSED',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFACC15),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('RESUME MATCH',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _hasShownGameOverModal = false;
                        game.resetPositions(isPlayerServing: true);
                        game.playerScore = 0;
                        game.opponentScore = 0;
                        game.isGameOver = false;
                      });
                    },
                    child: const Text('RESTART MATCH',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444)),
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
                    icon: const Icon(Icons.home, size: 20),
                    label: const Text('QUIT TO LOBBY',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToSummary() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MatchSummaryScreen(
          userName: widget.userName,
          characterStyle: widget.characterStyle,
          playerScore: playerScore,
          opponentScore: opponentScore,
          aiDupr: widget.aiDupr,
          isVictory: playerScore > opponentScore,
          isTournamentMatch: widget.isTournamentMatch,
          tournamentRound: widget.tournamentRound,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final bool isLandscape = orientation == Orientation.landscape;

            return GestureDetector(
              onPanStart: (details) {
                final RenderBox? box = context.findRenderObject() as RenderBox?;
                if (box != null) {
                  final localPos = box.globalToLocal(details.globalPosition);
                  final normX = ((localPos.dx / box.size.width) - 0.5) * 2.0;
                  final normY = ((localPos.dy / box.size.height) - 0.5) * 2.0;
                  game.updateAim(Offset(normX, normY));
                }
              },
              onPanUpdate: (details) {
                final RenderBox? box = context.findRenderObject() as RenderBox?;
                if (box != null) {
                  final localPos = box.globalToLocal(details.globalPosition);
                  final normX = ((localPos.dx / box.size.width) - 0.5) * 2.0;
                  final normY = ((localPos.dy / box.size.height) - 0.5) * 2.0;
                  game.updateAim(Offset(normX, normY));
                }
              },
              onPanEnd: (details) {
                game.triggerDragAttack(Offset.zero, selectedShotType);
              },
              onPanCancel: () {
                game.cancelAim();
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PerspectiveCourtPainter(
                        ballX: ballX,
                        ballY: ballY,
                        ballHeight: ballHeight,
                        playerX: playerX,
                        playerY: playerY,
                        opponentX: opponentX,
                        opponentY: opponentY,
                        orbX: orbX,
                        orbY: orbY,
                        orbType: orbType,
                        isDoublePointsActive: isDoublePointsActive,
                        isAiShrunk: isAiShrunk,
                        timingFeedback: timingFeedback,
                        playerColor: widget.characterStyle.outfitPrimary,
                        isUltimateActive: isUltimateActive,
                        playerAnimState: playerAnimState,
                        aiAnimState: aiAnimState,
                        playerFrame: playerFrame,
                        aiFrame: aiFrame,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.01,
                      child: GameWidget(game: game),
                    ),
                  ),
                  Positioned(
                    top: isLandscape ? 6 : 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildHeaderIconButton(Icons.pause, _openPauseMenu),
                            const SizedBox(width: 8),
                            _buildHeaderIconButton(Icons.home, _openPauseMenu),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLandscape ? 12 : 16,
                            vertical: isLandscape ? 4 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFACC15), width: 2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.radio,
                                  color: Color(0xFFFACC15), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '$playerScore - $opponentScore',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isLandscape ? 16 : 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDoublePointsActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEAB308),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('2X POINTS',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10)),
                          )
                        else
                          const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Positioned(
                    top: isLandscape ? 44 : 68,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          matchStatus,
                          style: const TextStyle(
                              color: Color(0xFFFACC15),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0),
                        ),
                      ),
                    ),
                  ),
                  if (!isGameOver) ...[
                    Positioned(
                      left: isLandscape ? 16 : 24,
                      bottom: isLandscape ? 12 : 24,
                      child: TouchJoystickWheel(
                        onJoystickMoved: (Offset direction) {
                          game.updatePlayerMovement(direction);
                        },
                      ),
                    ),
                    Positioned(
                      right: isLandscape ? 16 : 20,
                      bottom: isLandscape ? 10 : 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStreetButton(
                                label: 'SLICE',
                                onPressed: () =>
                                    setState(() => selectedShotType = 'SLICE'),
                                isPrimary: selectedShotType == 'SLICE',
                                isLandscape: isLandscape,
                              ),
                              SizedBox(width: isLandscape ? 8 : 12),
                              _buildStreetButton(
                                label: 'DRIVE',
                                onPressed: () =>
                                    setState(() => selectedShotType = 'DRIVE'),
                                isPrimary: selectedShotType == 'DRIVE',
                                isLandscape: isLandscape,
                              ),
                            ],
                          ),
                          SizedBox(height: isLandscape ? 6 : 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStreetButton(
                                label: 'LOB',
                                onPressed: () =>
                                    setState(() => selectedShotType = 'LOB'),
                                isPrimary: selectedShotType == 'LOB',
                                isLandscape: isLandscape,
                              ),
                              SizedBox(width: isLandscape ? 8 : 12),
                              _buildStreetButton(
                                label: 'SMASH',
                                onPressed: () =>
                                    setState(() => selectedShotType = 'SMASH'),
                                isPrimary: selectedShotType == 'SMASH',
                                isLandscape: isLandscape,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFACC15), width: 1.5),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildStreetButton({
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isLandscape = false,
  }) {
    final double size =
        isLandscape ? (isPrimary ? 58 : 50) : (isPrimary ? 72 : 64);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFDC2626) : const Color(0xFF27272A),
          shape: BoxShape.circle,
          border: Border.all(
              color: isPrimary ? const Color(0xFFFACC15) : Colors.white38,
              width: 2.0),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: isLandscape ? 9 : 11),
          ),
        ),
      ),
    );
  }
}

class TouchJoystickWheel extends StatefulWidget {
  final Function(Offset direction) onJoystickMoved;
  const TouchJoystickWheel({super.key, required this.onJoystickMoved});

  @override
  State<TouchJoystickWheel> createState() => _TouchJoystickWheelState();
}

class _TouchJoystickWheelState extends State<TouchJoystickWheel> {
  Offset _dragPosition = Offset.zero;
  final double _baseRadius = 50.0;
  final double _knobRadius = 20.0;

  void _updatePosition(Offset offset) {
    final double distance = offset.distance;
    final double maxDistance = _baseRadius - _knobRadius;
    Offset clampedOffset = offset;
    if (distance > maxDistance) {
      clampedOffset = Offset(
        (offset.dx / distance) * maxDistance,
        (offset.dy / distance) * maxDistance,
      );
    }
    setState(() {
      _dragPosition = clampedOffset;
    });
    final normalized = Offset(
      clampedOffset.dx / maxDistance,
      clampedOffset.dy / maxDistance,
    );
    widget.onJoystickMoved(normalized);
  }

  void _resetPosition() {
    setState(() {
      _dragPosition = Offset.zero;
    });
    widget.onJoystickMoved(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _updatePosition(
          details.localPosition - Offset(_baseRadius, _baseRadius)),
      onPanUpdate: (details) => _updatePosition(
          details.localPosition - Offset(_baseRadius, _baseRadius)),
      onPanEnd: (_) => _resetPosition(),
      onPanCancel: () => _resetPosition(),
      child: Container(
        width: _baseRadius * 2,
        height: _baseRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF18181B).withOpacity(0.80),
          border: Border.all(color: const Color(0xFFFACC15), width: 2.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: _dragPosition,
              child: Container(
                width: _knobRadius * 2,
                height: _knobRadius * 2,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFACC15),
                ),
                child:
                    const Icon(Icons.navigation, size: 14, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
