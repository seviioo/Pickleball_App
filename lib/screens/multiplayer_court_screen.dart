import 'dart:async';
import 'package:flutter/material.dart';
import '../game/pickleball_game.dart' as game;
import '../models/game_models.dart';
import '../painters/perspective_court_painter.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'court_gameplay_screen.dart';

class MultiplayerCourtScreen extends StatefulWidget {
  final String userName;
  final CharacterStyleData characterStyle;
  final String roomCode;
  final bool isHost;
  final String opponentName;

  const MultiplayerCourtScreen({
    super.key,
    required this.userName,
    required this.characterStyle,
    required this.roomCode,
    required this.isHost,
    required this.opponentName,
  });

  @override
  State<MultiplayerCourtScreen> createState() => _MultiplayerCourtScreenState();
}

class _MultiplayerCourtScreenState extends State<MultiplayerCourtScreen> {
  // Synchronized Player Coordinates
  double myX = 0.0;
  double myY = 0.85;
  double opponentX = 0.0;
  double opponentY = -0.85;

  // Synchronized Ball Dynamics
  double ballX = 0.0;
  double ballY = 0.0;
  double ballHeight = 0.4;

  int myScore = 0;
  int opponentScore = 0;
  bool isGameOver = false;
  String matchStatus = 'STREET SERVE READY';
  bool isPlayerServing = true;
  String playerAnimState = 'idle';
  String opponentAnimState = 'idle';
  bool _matchResultSubmitted = false;

  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _listenSocketEvents();
  }

  void _listenSocketEvents() {
    _socketSub = SocketService.instance.stream.listen((event) {
      if (!mounted) return;
      final type = event['type'];

      if (type == 'STATE') {
        setState(() {
          myScore = _number(event['myScore']).round();
          opponentScore = _number(event['opponentScore']).round();
          isPlayerServing = event['isServing'] == true;
          isGameOver = event['isGameOver'] == true;
          matchStatus = '${event['status'] ?? 'RALLY'}';
          ballX = _number(event['ballX']);
          ballY = _number(event['ballY']);
          ballHeight = _number(event['ballHeight']);
          myX = _number(event['myX']);
          myY = _number(event['myY']);
          opponentX = _number(event['opponentX']);
          opponentY = _number(event['opponentY']);
          playerAnimState = '${event['playerAnimState'] ?? 'idle'}';
          opponentAnimState = '${event['opponentAnimState'] ?? 'idle'}';
        });
        if (isGameOver && !_matchResultSubmitted) {
          _handleMatchEnd(myScore > opponentScore);
        }
      }
    });
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  game.CharacterAnimState _animationFor(String value) {
    switch (value) {
      case 'walking':
        return game.CharacterAnimState.walkingUp;
      case 'drive':
        return game.CharacterAnimState.drive;
      case 'slice':
        return game.CharacterAnimState.slice;
      case 'lob':
        return game.CharacterAnimState.lob;
      case 'smash':
        return game.CharacterAnimState.smash;
      case 'serving':
        return game.CharacterAnimState.serving;
      default:
        return game.CharacterAnimState.idle;
    }
  }

  void _onJoystickMove(Offset direction) {
    setState(() {
      myX = (myX + direction.dx * 0.03).clamp(-0.92, 0.92);
      myY = (myY + direction.dy * 0.03).clamp(0.20, 1.10);
    });

    SocketService.instance.sendEvent('MOVE', {
      'dx': direction.dx,
      'dy': direction.dy,
    });
  }

  void _triggerShot(String type) {
    if (isGameOver) return;
    SocketService.instance.sendEvent('SHOT', {
      'shotType': type,
      'x': myX,
      'y': myY,
    });
  }

  void _handleMatchEnd(bool isWinner) async {
    if (_matchResultSubmitted) return;
    _matchResultSubmitted = true;
    setState(() {
      isGameOver = true;
      matchStatus = isWinner ? 'VICTORY!' : 'DEFEATED!';
    });

    final String idempotencyKey = '${widget.roomCode}_${widget.userName}_end';
    await ApiService.submitMatchResult(
      username: widget.userName,
      matchId: widget.roomCode,
      roomCode: widget.roomCode,
      playerScore: myScore,
      opponentScore: opponentScore,
      isWinner: isWinner,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Stack(
          children: [
            // Perspective Court Painter (Uses identical parameters as VS AI)
            Positioned.fill(
              child: CustomPaint(
                painter: PerspectiveCourtPainter(
                  ballX: ballX,
                  ballY: ballY,
                  ballHeight: ballHeight,
                  playerX: myX,
                  playerY: myY,
                  opponentX: opponentX,
                  opponentY: opponentY,
                  isDoublePointsActive: false,
                  isAiShrunk: false,
                  playerColor: widget.characterStyle.outfitPrimary,
                  playerAnimState: _animationFor(playerAnimState),
                  aiAnimState: _animationFor(opponentAnimState),
                  playerFrame: 0,
                  aiFrame: 0,
                ),
              ),
            ),

            // Header Scoreboard
            Positioned(
              top: isLandscape ? 6 : 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 12 : 16,
                      vertical: isLandscape ? 4 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFFACC15), width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radio,
                            color: Color(0xFFFACC15), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.userName}: $myScore  |  ${widget.opponentName}: $opponentScore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isLandscape ? 14 : 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Status Banner
            Positioned(
              top: isLandscape ? 44 : 68,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    matchStatus,
                    style: const TextStyle(
                      color: Color(0xFFFACC15),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // Touch Controls
            if (!isGameOver) ...[
              Positioned(
                left: isLandscape ? 36 : 24,
                bottom: isLandscape ? 16 : 24,
                child: TouchJoystickWheel(
                  onJoystickMoved: _onJoystickMove,
                ),
              ),
              Positioned(
                right: isLandscape ? 36 : 20,
                bottom: isLandscape ? 12 : 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStreetButton(
                          label: 'SLICE',
                          onPressed: () => _triggerShot('ROLL'),
                        ),
                        const SizedBox(width: 12),
                        _buildStreetButton(
                          label: 'DRIVE',
                          onPressed: () => _triggerShot('DRIVE'),
                          isPrimary: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStreetButton(
                          label: 'LOB',
                          onPressed: () => _triggerShot('LOB'),
                        ),
                        const SizedBox(width: 12),
                        _buildStreetButton(
                          label: 'SMASH',
                          onPressed: () => _triggerShot('SMASH'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreetButton({
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isPrimary ? 72 : 64,
        height: isPrimary ? 72 : 64,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFDC2626) : const Color(0xFF27272A),
          shape: BoxShape.circle,
          border: Border.all(
            color: isPrimary ? const Color(0xFFFACC15) : Colors.white38,
            width: 2.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
