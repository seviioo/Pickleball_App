import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../game/pickleball_game.dart' as game;
import '../models/game_models.dart';
import '../painters/perspective_court_painter.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'court_gameplay_screen.dart';
import 'lobby_screen.dart';
import 'match_summary_screen.dart';

class _CourtFrame {
  final double ballX;
  final double ballY;
  final double ballHeight;
  final double ballVx;
  final double ballVy;
  final double ballVz;
  final double ballRotation;
  final double myX;
  final double myY;
  final double opponentX;
  final double opponentY;
  final double playerActionProgress;
  final double opponentActionProgress;

  const _CourtFrame({
    required this.ballX,
    required this.ballY,
    required this.ballHeight,
    required this.ballVx,
    required this.ballVy,
    required this.ballVz,
    required this.ballRotation,
    required this.myX,
    required this.myY,
    required this.opponentX,
    required this.opponentY,
    required this.playerActionProgress,
    required this.opponentActionProgress,
  });

  factory _CourtFrame.interpolate(
    _CourtFrame previous,
    _CourtFrame current,
    double progress,
  ) {
    double lerp(double from, double to) => from + (to - from) * progress;

    return _CourtFrame(
      ballX: lerp(previous.ballX, current.ballX),
      ballY: lerp(previous.ballY, current.ballY),
      ballHeight: lerp(previous.ballHeight, current.ballHeight),
      ballVx: lerp(previous.ballVx, current.ballVx),
      ballVy: lerp(previous.ballVy, current.ballVy),
      ballVz: lerp(previous.ballVz, current.ballVz),
      ballRotation: lerp(previous.ballRotation, current.ballRotation),
      myX: lerp(previous.myX, current.myX),
      myY: lerp(previous.myY, current.myY),
      opponentX: lerp(previous.opponentX, current.opponentX),
      opponentY: lerp(previous.opponentY, current.opponentY),
      playerActionProgress:
          lerp(previous.playerActionProgress, current.playerActionProgress),
      opponentActionProgress: lerp(
        previous.opponentActionProgress,
        current.opponentActionProgress,
      ),
    );
  }
}

class MultiplayerCourtScreen extends StatefulWidget {
  final String userName;
  final CharacterStyleData characterStyle;
  final String roomCode;
  final bool isHost;
  final String opponentName;
  final PaddleData paddle;

  const MultiplayerCourtScreen({
    super.key,
    required this.userName,
    required this.characterStyle,
    required this.roomCode,
    required this.isHost,
    required this.opponentName,
    required this.paddle,
  });

  @override
  State<MultiplayerCourtScreen> createState() => _MultiplayerCourtScreenState();
}

class _MultiplayerCourtScreenState extends State<MultiplayerCourtScreen>
    with SingleTickerProviderStateMixin {
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
  bool ballInReach = false;
  String playerAnimState = 'idle';
  String opponentAnimState = 'idle';
  double playerActionProgress = 1;
  double opponentActionProgress = 1;
  Offset _aimDirection = Offset.zero;
  bool _paused = false;
  double _animClock = 0;
  PaddleData get _playerPaddle => widget.paddle;
  bool _matchResultSubmitted = false;
  Offset _movementDirection = Offset.zero;
  Timer? _movementTimer;
  late final Ticker _renderTicker;
  final Stopwatch _renderClock = Stopwatch();
  _CourtFrame? _previousFrame;
  _CourtFrame? _latestFrame;
  Duration _latestFrameAt = Duration.zero;

  static const Duration _snapshotInterval = Duration(milliseconds: 50);
  double get _playerReach => 0.30 + (_playerPaddle.control / 100.0) * 0.10;
  double get _aimPreviewX {
    final dx = _aimDirection.dx;
    if (matchPhase == 'ready') {
      return (dx.abs() > 0.25 ? dx * 0.6 : 0.0).clamp(-0.7, 0.7).toDouble();
    }
    return dx.abs() > 0.25
        ? (dx.sign * (0.35 + 0.5 * dx.abs())).clamp(-0.92, 0.92).toDouble()
        : 0.0;
  }

  double get _aimPreviewY {
    if (matchPhase == 'ready') return -0.65;
    final dy = _aimDirection.dy;
    return dy.abs() < 0.35
        ? -0.75
        : (-0.75 + dy * 0.20).clamp(-0.92, -0.35).toDouble();
  }

  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _renderTicker = createTicker(_renderFrame);
    _listenSocketEvents();
  }

  void _renderFrame(Duration _) {
    final previous = _previousFrame;
    final current = _latestFrame;
    if (previous == null || current == null || !mounted) return;

    final elapsedSinceSnapshot = _renderClock.elapsed - _latestFrameAt;
    final progress =
        (elapsedSinceSnapshot.inMicroseconds / _snapshotInterval.inMicroseconds)
            .clamp(0.0, 1.0)
            .toDouble();
    final frame = _CourtFrame.interpolate(previous, current, progress);
    setState(() {
      ballX = frame.ballX;
      ballY = frame.ballY;
      ballHeight = frame.ballHeight;
      ballVx = frame.ballVx;
      ballVy = frame.ballVy;
      ballVz = frame.ballVz;
      ballRotation = frame.ballRotation;
      myX = frame.myX;
      myY = frame.myY;
      opponentX = frame.opponentX;
      opponentY = frame.opponentY;
      playerActionProgress = frame.playerActionProgress;
      opponentActionProgress = frame.opponentActionProgress;
      _animClock = _renderClock.elapsed.inMicroseconds / 1000000;
    });
  }

  void _listenSocketEvents() {
    _socketSub = SocketService.instance.stream.listen((event) {
      if (!mounted) return;
      final type = event['type'];

      if (type == 'STATE') {
        final frame = _CourtFrame(
          ballX: _number(event['ballX']),
          ballY: _number(event['ballY']),
          ballHeight: _number(event['ballHeight']),
          ballVx: _number(event['ballVx']),
          ballVy: _number(event['ballVy']),
          ballVz: _number(event['ballVz']),
          ballRotation: _number(event['ballRotation']),
          myX: _number(event['myX']),
          myY: _number(event['myY']),
          opponentX: _number(event['opponentX']),
          opponentY: _number(event['opponentY']),
          playerActionProgress:
              _number(event['playerActionProgress']).clamp(0, 1),
          opponentActionProgress:
              _number(event['opponentActionProgress']).clamp(0, 1),
        );
        setState(() {
          myScore = _number(event['myScore']).round();
          opponentScore = _number(event['opponentScore']).round();
          isPlayerServing = event['isServing'] == true;
          ballInReach = event['ballInReach'] == true;
          matchPhase = '${event['phase'] ?? 'rally'}';
          _hasAuthoritativeState = true;
          isGameOver = event['isGameOver'] == true;
          matchStatus = '${event['status'] ?? 'RALLY'}';
          playerAnimState = '${event['playerAnimState'] ?? 'idle'}';
          opponentAnimState = '${event['opponentAnimState'] ?? 'idle'}';
          _paused = event['paused'] == true;
          _previousFrame = _latestFrame ?? frame;
          _latestFrame = frame;
          if (!_renderClock.isRunning) _renderClock.start();
          _latestFrameAt = _renderClock.elapsed;
        });
        if (!_renderTicker.isActive) _renderTicker.start();
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
    if (isGameOver || _paused) return;
    SocketService.instance.sendEvent('SHOT', {
      'shotType': type,
      'aimX': _aimDirection.dx.clamp(-1.0, 1.0),
      'aimY': _aimDirection.dy.clamp(-1.0, 1.0),
    });
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
    _renderTicker.dispose();
    _renderClock.stop();
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
                  playerReach: _playerReach,
                  ballInReach: ballInReach,
                  aimX: _aimPreviewX,
                  aimY: _aimPreviewY,
                  aimScatter: 0.12 * (1.25 - _playerPaddle.control / 100.0),
                  showAim: _hasAuthoritativeState &&
                      !_paused &&
                      !isGameOver &&
                      ((matchPhase == 'ready' && isPlayerServing) ||
                          (matchPhase == 'rally' && ballInReach)),
                ),
              ),
            ),

            // Top Responsive Header HUD Bar
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                  const Spacer(),
                  // Flexible Scoreboard Box
                  Flexible(
                    flex: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 14 : 10,
                        vertical: isLandscape ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFACC15), width: 2),
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
                              textAlign: TextAlign.center,
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
                  const Spacer(),
                ],
              ),
            ),

            // Status Banner Positioned Safely Clear of Opponent Character
            Positioned(
              top: isLandscape ? 56 : 68,
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
                    if (matchPhase == 'ready' && isPlayerServing)
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
