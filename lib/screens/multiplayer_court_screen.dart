import 'dart:async';
import 'package:flutter/material.dart';
import '../game/pickleball_game.dart' as game;
import '../models/game_models.dart';
import '../painters/perspective_court_painter.dart'; // Defines CharacterAnimState
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'court_gameplay_screen.dart'; // Provides TouchJoystickWheel widget

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

      if (type == 'MOVE') {
        setState(() {
          opponentX = event['x'];
          opponentY = event['y'];
        });
      } else if (type == 'BALL') {
        setState(() {
          ballX = event['x'];
          ballY = event['y'];
          ballHeight = event['h'];
        });
      } else if (type == 'SCORE') {
        setState(() {
          myScore = widget.isHost ? event['hostScore'] : event['guestScore'];
          opponentScore =
              widget.isHost ? event['guestScore'] : event['hostScore'];
          matchStatus = 'POINT OUT';
        });
      } else if (type == 'MATCH_END') {
        _handleMatchEnd(event['winner'] == widget.userName);
      }
    });
  }

  void _onJoystickMove(Offset direction) {
    setState(() {
      myX = (myX + direction.dx * 0.03).clamp(-0.92, 0.92);
      myY = (myY + direction.dy * 0.03).clamp(0.20, 1.10);
    });

    SocketService.instance.sendEvent('MOVE', {
      'roomCode': widget.roomCode,
      'x': -myX,
      'y': -myY,
    });
  }

  void _triggerShot(String type) {
    SocketService.instance.sendEvent('SHOT', {
      'roomCode': widget.roomCode,
      'shotType': type,
      'x': myX,
      'y': myY,
    });
  }

  void _handleMatchEnd(bool isWinner) async {
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
                  playerAnimState: game.CharacterAnimState.idle,
                  aiAnimState: game.CharacterAnimState.idle,
                  playerFrame: 0,
                  aiFrame: 0,
                ),
              ),
            ),

            // Header Scoreboard (VS AI Yellow Theme)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
              top: 68,
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
                left: 24,
                bottom: 24,
                child: TouchJoystickWheel(
                  onJoystickMoved: _onJoystickMove,
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
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
