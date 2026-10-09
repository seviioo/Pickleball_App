import 'dart:async';
import 'package:flutter/material.dart';
import '../game/pickleball_game.dart' as game;
import '../models/game_models.dart';
import '../painters/perspective_court_painter.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'court_gameplay_screen.dart';
import 'lobby_screen.dart';
import 'match_summary_screen.dart';

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
  double ballVx = 0;
  double ballVy = 0;
  double ballVz = 0;
  double ballRotation = 0;

  int myScore = 0;
  int opponentScore = 0;
  bool isGameOver = false;
  bool _hasAuthoritativeState = false;
  String matchPhase = 'connecting';
  String matchStatus = 'STREET SERVE READY';
  bool isPlayerServing = true;
  String playerAnimState = 'idle';
  String opponentAnimState = 'idle';
  double playerActionProgress = 1;
  double opponentActionProgress = 1;
  Offset _aimDirection = Offset.zero;
  bool _paused = false;
  double _animClock = 0;
  final PaddleData _playerPaddle = PaddleData.starter();
  bool _matchResultSubmitted = false;
  Offset _movementDirection = Offset.zero;
  Timer? _movementTimer;

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
          matchPhase = '${event['phase'] ?? 'rally'}';
          _hasAuthoritativeState = true;
          isGameOver = event['isGameOver'] == true;
          matchStatus = '${event['status'] ?? 'RALLY'}';
          ballX = _number(event['ballX']);
          ballY = _number(event['ballY']);
          ballHeight = _number(event['ballHeight']);
          ballVx = _number(event['ballVx']);
          ballVy = _number(event['ballVy']);
          ballVz = _number(event['ballVz']);
          ballRotation = _number(event['ballRotation']);
          myX = _number(event['myX']);
          myY = _number(event['myY']);
          opponentX = _number(event['opponentX']);
          opponentY = _number(event['opponentY']);
          playerAnimState = '${event['playerAnimState'] ?? 'idle'}';
          opponentAnimState = '${event['opponentAnimState'] ?? 'idle'}';
          playerActionProgress =
              _number(event['playerActionProgress']).clamp(0, 1);
          opponentActionProgress =
              _number(event['opponentActionProgress']).clamp(0, 1);
          _paused = event['paused'] == true;
          _animClock += 0.05;
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
    _movementDirection = direction;
    _movementTimer ??= Timer.periodic(const Duration(milliseconds: 50), (_) {
      final direction = _movementDirection;
      SocketService.instance.sendEvent('MOVE', {
        'dx': direction.dx,
        'dy': direction.dy,
      });
      if (direction == Offset.zero) {
        _movementTimer?.cancel();
        _movementTimer = null;
      }
    });
  }

  void _triggerShot(String type) {
    if (isGameOver ||
        _paused ||
        !_hasAuthoritativeState ||
        (matchPhase == 'ready' && !isPlayerServing) ||
        (matchPhase != 'ready' && matchPhase != 'rally')) {
      return;
    }
    final targetY = _aimTargetY(type);
    SocketService.instance.sendEvent('SHOT', {
      'shotType': type,
      'targetX': _aimTargetX,
      'targetY': targetY,
      'y': myY,
      'aimX': _aimDirection.dx,
      'aimY': targetY,
    });
  }

  bool get _isAimingSideways => _aimDirection.dx.abs() > 0.25;

  double get _aimTargetX {
    if (!_isAimingSideways) return 0.0;
    if (matchPhase == 'ready') {
      return (_aimDirection.dx * 0.6).clamp(-0.7, 0.7).toDouble();
    }
    return (_aimDirection.dx.sign * (0.35 + 0.5 * _aimDirection.dx.abs()))
        .clamp(-0.92, 0.92)
        .toDouble();
  }

  double _aimTargetY([String shotType = 'DRIVE']) {
    final baseY = matchPhase == 'ready'
        ? -0.65
        : shotType == 'ROLL' || shotType == 'SLICE'
            ? -0.28
            : shotType == 'LOB'
                ? -0.85
                : shotType == 'SMASH'
                    ? -0.80
                    : -0.75;
    final dy = _aimDirection.dy;
    if (matchPhase == 'ready' || dy.abs() < 0.35) return baseY;
    if (shotType == 'ROLL' || shotType == 'SLICE') {
      return (baseY + dy * 0.06).clamp(-0.36, -0.20).toDouble();
    }
    final range = shotType == 'LOB' ? 0.06 : 0.20;
    return (baseY + dy * range).clamp(-0.92, -0.35).toDouble();
  }

  void _updateAim(Offset direction) {
    _aimDirection = direction;
  }

  void _togglePause() {
    if (_paused) {
      SocketService.instance.sendEvent('RESUME', {});
    } else {
      SocketService.instance.sendEvent('PAUSE', {});
    }
  }

  void _handleMatchEnd(bool isWinner) async {
    if (_matchResultSubmitted) return;
    _matchResultSubmitted = true;
    setState(() {
      isGameOver = true;
      matchStatus = isWinner ? 'VICTORY!' : 'DEFEATED!';
    });

    final String idempotencyKey = '${widget.roomCode}_${widget.userName}_end';
    try {
      await ApiService.submitMatchResult(
        username: widget.userName,
        matchId: widget.roomCode,
        roomCode: widget.roomCode,
        playerScore: myScore,
        opponentScore: opponentScore,
        isWinner: isWinner,
        idempotencyKey: idempotencyKey,
      );
    } catch (error) {
      debugPrint('Multiplayer match result sync unavailable: $error');
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchSummaryScreen(
          userName: widget.userName,
          characterStyle: widget.characterStyle,
          isVictory: isWinner,
          playerScore: myScore,
          opponentScore: opponentScore,
          opponentName: widget.opponentName,
        ),
      ),
    );
    if (mounted) _goHome();
  }

  void _goBack() {
    SocketService.instance.disconnect();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _goHome();
    }
  }

  void _goHome() {
    SocketService.instance.disconnect();
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
  }

  @override
  void dispose() {
    _movementDirection = Offset.zero;
    _movementTimer?.cancel();
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
                  playerPaddle: _playerPaddle,
                  ballVx: ballVx,
                  ballVy: ballVy,
                  ballVz: ballVz,
                  ballRotation: ballRotation,
                  animClock: _animClock,
                  playerActionProgress: playerActionProgress,
                  aiActionProgress: opponentActionProgress,
                  playerMoveAmount: _movementDirection.distance.clamp(0, 1),
                  playerMoveX: _movementDirection.dx.clamp(-1, 1),
                  aiMoveAmount: opponentAnimState == 'walking' ? 0.7 : 0.0,
                  aiMoveX: 0,
                  playerReach: 0.22,
                  ballInReach: _hasAuthoritativeState &&
                      ((matchPhase == 'ready' && isPlayerServing) ||
                          (matchPhase == 'rally' && ballHeight < 0.8)),
                  aimX: _aimTargetX,
                  aimY: _aimTargetY(),
                  aimScatter: 0.15,
                  showAim: _hasAuthoritativeState &&
                      !_paused &&
                      !isGameOver &&
                      ((matchPhase == 'ready' && isPlayerServing) ||
                          (matchPhase == 'rally' && ballHeight < 0.8)),
                ),
              ),
            ),

            // The AI screen uses pause and home in the side header.
            Positioned(
              top: isLandscape ? 8 : 12,
              left: isLandscape ? 12 : 8,
              child: Row(
                children: [
                  _buildNavigationButton(
                    icon: _paused ? Icons.play_arrow_rounded : Icons.pause,
                    onPressed: _togglePause,
                    tooltip: _paused ? 'Resume' : 'Pause',
                  ),
                  const SizedBox(width: 6),
                  _buildNavigationButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: _goBack,
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 6),
                  _buildNavigationButton(
                    icon: Icons.home_rounded,
                    onPressed: _goHome,
                    tooltip: 'Home',
                  ),
                ],
              ),
            ),

            // Header Scoreboard
            Positioned(
              top: isLandscape ? 8 : 12,
              left: isLandscape ? 150 : 124,
              right: isLandscape ? 150 : 8,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLandscape ? 400 : 260,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 12 : 10,
                      vertical: isLandscape ? 4 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFFACC15), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.radio,
                          color: Color(0xFFFACC15),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${widget.userName}: $myScore  |  ${widget.opponentName}: $opponentScore',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isLandscape ? 14 : 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Status Banner
            Positioned(
              top: isLandscape ? 54 : 82,
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

            if (_paused)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B).withOpacity(0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFACC15)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('MATCH PAUSED',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _togglePause,
                          child: const Text('RESUME'),
                        ),
                        TextButton(
                          onPressed: _goHome,
                          child: const Text('LEAVE MATCH'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Touch Controls match Player-vs-AI: joystick plus drag-to-aim shots.
            if (!isGameOver && !_paused) ...[
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
                    if (_hasAuthoritativeState &&
                        matchPhase == 'ready' &&
                        isPlayerServing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAimableButton(
                          label: 'SERVE',
                          shotType: 'SERVE',
                          isPrimary: true,
                          width: 130,
                          height: 48,
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAimableButton(
                          label: 'SLICE',
                          shotType: 'ROLL',
                        ),
                        const SizedBox(width: 12),
                        _buildAimableButton(
                          label: 'DRIVE',
                          shotType: 'DRIVE',
                          isPrimary: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAimableButton(
                          label: 'LOB',
                          shotType: 'LOB',
                        ),
                        const SizedBox(width: 12),
                        _buildAimableButton(
                          label: 'SMASH',
                          shotType: 'SMASH',
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

  Widget _buildAimableButton({
    required String label,
    required String shotType,
    bool isPrimary = false,
    double? width,
    double? height,
  }) {
    return AimableShotButton(
      label: label,
      isPrimary: isPrimary,
      width: width,
      height: height,
      onAim: _updateAim,
      onShoot: () => _triggerShot(shotType),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 24),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.72),
          side: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}
