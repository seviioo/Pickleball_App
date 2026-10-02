import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/audio_service.dart';

enum OrbType { speedDemon, shrinkRay, doublePoints }

enum CharacterAnimState {
  idle,
  walkingUp,
  walkingDown,
  walkingLeft,
  walkingRight,
  serving,
  drive,
  smash,
  slice,
  lob,
}

/// One remembered ball position, used to draw the motion trail.
class BallTrailPoint {
  final double x;
  final double y;
  final double h;
  const BallTrailPoint(this.x, this.y, this.h);
}

typedef GameStateCallback = void Function({
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
});

enum RallyPhase { readyToServe, inFlight, activeRally }

class PickleballGame extends FlameGame {
  final String userName;
  final PaddleData paddle;
  final CharacterStyleData characterStyle;
  final int targetScore;
  final double aiDupr;
  final GameStateCallback onStateUpdate;

  int playerScore = 0;
  int opponentScore = 0;
  bool isPlayerServing = true;
  bool isGameOver = false;
  String matchStatus = 'STREET SERVE READY';
  String? timingFeedback;
  RallyPhase phase = RallyPhase.readyToServe;

  double ultimateGauge = 0.0;
  bool isUltimateActive = false;

  double ballX = 0.0;
  double ballY = 0.85;
  double ballHeight = 0.40;
  double ballVx = 0.0;
  double ballVy = 0.0;
  double ballVz = 0.0;

  double playerX = 0.0;
  double playerY = 0.85;
  double opponentX = 0.0;
  double opponentY = -0.85;

  // Animation States
  CharacterAnimState playerAnimState = CharacterAnimState.idle;
  CharacterAnimState aiAnimState = CharacterAnimState.idle;
  double playerAnimTimer = 0.0;
  double aiAnimTimer = 0.0;
  double playerAnimDuration = 0.4;
  double aiAnimDuration = 0.4;

  // Continuous animation data (read by the painter every frame)
  double animClock = 0.0;
  double playerWalkPhase = 0.0;
  double aiWalkPhase = 0.0;
  double aiVelX = 0.0;
  double aiVelY = 0.0;

  /// 0 -> 1 while a hit animation plays, 1 when idle.
  double get playerAnimProgress => playerAnimTimer > 0
      ? (1.0 - playerAnimTimer / playerAnimDuration).clamp(0.0, 1.0).toDouble()
      : 1.0;
  double get aiAnimProgress => aiAnimTimer > 0
      ? (1.0 - aiAnimTimer / aiAnimDuration).clamp(0.0, 1.0).toDouble()
      : 1.0;

  // ---------------------------------------------------------------
  // AI DIFFICULTY  (aiDupr: 2.5 = Rookie, 4.0 = Pro Tour, 5.5 = Titan)
  // Everything below scales smoothly with the rating.
  // ---------------------------------------------------------------
  /// 0.0 at Rookie -> 1.0 at Titan
  double get _aiSkill => ((aiDupr - 2.5) / 3.0).clamp(0.0, 1.0).toDouble();

  /// Run speed. Rookie is slow, Titan is faster than the human player (1.4).
  double get _aiTopSpeed => 0.95 + (aiDupr - 2.5) * 0.20;

  /// Seconds before the AI starts reacting to your shot.
  double get _aiReactTime =>
      (0.45 - (aiDupr - 2.5) * 0.12).clamp(0.08, 0.45).toDouble();

  /// How far off its read of the ball's landing spot the AI is.
  double get _aiTrackError =>
      (0.30 - (aiDupr - 2.5) * 0.0867).clamp(0.04, 0.30).toDouble();

  /// Paddle reach (the human's is ~0.36).
  double get _aiReach => 0.32 + (aiDupr - 2.5) * 0.04;

  /// Chance of a routine unforced error (before pressure is added).
  double get _aiBaseMiss =>
      (0.22 - (aiDupr - 2.5) * 0.0667).clamp(0.02, 0.30).toDouble();

  /// Chance the AI aims away from you instead of hitting randomly.
  double get _aiPlacement =>
      (0.15 + (aiDupr - 2.5) * 0.20).clamp(0.10, 0.80).toDouble();

  /// Multiplier on shot flight time: >1 = slower shots (Rookie), <1 = faster (Titan).
  double get _aiShotTimeScale => 1.10 - (aiDupr - 2.5) * 0.0667;

  double get aiMoveAmount =>
      (sqrt(aiVelX * aiVelX + aiVelY * aiVelY) / _aiTopSpeed)
          .clamp(0.0, 1.0)
          .toDouble();

  // Player reach: the radius around the player the paddle can actually cover.
  // A better-control paddle reaches slightly farther.
  double get playerReach => 0.30 + (paddle.control / 100.0) * 0.10;

  double _playerSwingCooldown = 0.0;
  bool get ballInPlayerReach =>
      phase != RallyPhase.readyToServe &&
      !_lastHitByPlayer &&
      sqrt(pow(ballX - playerX, 2) + pow(ballY - playerY, 2)) <= playerReach &&
      ballHeight <= 1.20;

  // AI "brain"
  double _aiReactTimer = 0.0;
  double _aiAimErrX = 0.0;
  String _aiLastShot = 'DRIVE';
  final Random _rng = Random();

  int playerFrame = 0;
  int aiFrame = 0;
  double playerStepTimer = 0.0;
  double aiStepTimer = 0.0;

  // Power Orbs
  double? orbX;
  double? orbY;
  OrbType? orbType;
  double _orbSpawnTimer = 0.0;
  bool isDoublePointsActive = false;
  double _aiShrinkTimer = 0.0;

  Offset playerInputDir = Offset.zero;
  double _aiServeTimer = 0.0;
  int _bounceCount = 0;

  // Match Breakdown Stat Trackers
  int smashesLanded = 0;
  int longestRally = 0;
  int kitchenFaults = 0;
  int _currentRallyHits = 0;

  // ---------------------------------------------------------------
  // BALL PHYSICS TUNING  (change these to adjust the feel)
  // ---------------------------------------------------------------
  /// Downward pull. Higher = ball drops faster, arcs are lower/snappier.
  static const double gravity = 8.0;

  /// Air resistance (wiffle-style ball). Higher = ball slows down more in flight.
  static const double airDrag = 0.35;

  /// How much vertical speed is kept on a bounce (1.0 = perfectly bouncy).
  static const double bounceRestitution = 0.66;

  /// How much sideways/forward speed is kept on a bounce (court friction).
  static const double bounceFriction = 0.82;

  /// How strongly spin bends the arc (topspin dips, backspin floats).
  static const double spinMagnus = 0.5;

  /// Net height in "ball height" units (the painter draws the net to match).
  static const double netHeight = 0.55;

  /// Shots are auto-lifted until they clear the net by at least this much.
  static const double netClearance = 0.08;

  /// Fixed physics sub-step so the ball behaves the same at any frame rate.
  static const double _physicsStep = 1 / 120;

  // Ball state used by physics + visuals
  double ballSpin = 0.0; // +topspin, -backspin
  double _gEff = gravity; // gravity + spin (Magnus) pull for the current shot
  double ballRotation = 0.0;
  double ballImpactTimer = 0.0; // squash timer (hit / bounce)
  final List<BallTrailPoint> trail = [];

  bool _lastHitByPlayer = true;
  bool _isServeInFlight = false;

  PickleballGame({
    required this.userName,
    required this.paddle,
    required this.characterStyle,
    required this.targetScore,
    required this.aiDupr,
    required this.onStateUpdate,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    resetPositions(isPlayerServing: true);
  }

  void resetPositions({required bool isPlayerServing}) {
    this.isPlayerServing = isPlayerServing;
    phase = RallyPhase.readyToServe;
    isUltimateActive = false;
    isDoublePointsActive = false;
    _bounceCount = 0;
    _currentRallyHits = 0;
    ballSpin = 0.0;
    _gEff = gravity;
    ballImpactTimer = 0.0;
    _isServeInFlight = false;
    trail.clear();

    aiVelX = 0.0;
    aiVelY = 0.0;
    _aiReactTimer = 0.0;
    _aiLastShot = 'DRIVE';

    orbX = null;
    orbY = null;
    orbType = null;
    _aiShrinkTimer = 0.0;

    playerX = 0.0;
    playerY = 0.85;
    opponentX = 0.0;
    opponentY = -0.85;

    playerAnimState = CharacterAnimState.idle;
    aiAnimState = CharacterAnimState.idle;

    _snapBallToServerHand();
    ballVx = 0.0;
    ballVy = 0.0;
    ballVz = 0.0;

    matchStatus = isPlayerServing ? 'YOUR SERVE' : 'AI SERVING...';
    _notifyState();
  }

  void _snapBallToServerHand() {
    if (isPlayerServing) {
      ballX = playerX + 0.08;
      ballY = playerY - 0.02;
      ballHeight = 0.40;
    } else {
      ballX = opponentX - 0.08;
      ballY = opponentY + 0.02;
      ballHeight = 0.30;
    }
  }

  void updatePlayerMovement(Offset dir) {
    playerInputDir = dir;
  }

  // ---------------- Player aiming ----------------
  // The joystick doubles as the aim stick when you hit:
  //   left / right = send the ball to that side
  //   up           = deeper (toward the baseline)
  //   down         = shorter (drops closer to the net)
  // No stick input = roughly down the middle with a little scatter.

  /// Shot scatter in court units: better-control paddles are more accurate.
  double get _aimScatter => 0.12 * (1.25 - paddle.control / 100.0);

  bool get _isAimingSideways => playerInputDir.dx.abs() > 0.25;
  double get _aimSideTarget =>
      playerInputDir.dx.sign * (0.35 + 0.5 * playerInputDir.dx.abs());

  double _playerAimX() {
    if (_isAimingSideways) {
      return (_aimSideTarget + (_rng.nextDouble() - 0.5) * 2.0 * _aimScatter)
          .clamp(-0.92, 0.92)
          .toDouble();
    }
    return (_rng.nextDouble() - 0.5) * 0.3;
  }

  double _playerServeAimX() {
    if (!_isAimingSideways) return (_rng.nextDouble() - 0.5) * 0.5;
    return (playerInputDir.dx * 0.6 + (_rng.nextDouble() - 0.5) * 0.1)
        .clamp(-0.7, 0.7)
        .toDouble();
  }

  /// Applies stick up/down to a shot's landing depth (opponent side is -Y).
  double _playerAimDepth(String shotType, double baseY) {
    final double dy = playerInputDir.dy;
    if (dy.abs() < 0.35) return baseY;
    final bool isDink = shotType == 'ROLL' || shotType == 'SLICE';
    if (isDink) {
      // Dinks must stay in the kitchen: only fine-tune them.
      return (baseY + dy * 0.06).clamp(-0.36, -0.20).toDouble();
    }
    final double range = shotType == 'LOB' ? 0.06 : 0.20;
    return (baseY + dy * range).clamp(-0.92, -0.35).toDouble();
  }

  /// Where the next shot is headed (drawn as a reticle on the court).
  Offset get playerAimPreview {
    if (phase == RallyPhase.readyToServe) {
      final double sx = _isAimingSideways
          ? (playerInputDir.dx * 0.6).clamp(-0.7, 0.7).toDouble()
          : 0.0;
      return Offset(sx, -0.65);
    }
    final double x =
        _isAimingSideways ? _aimSideTarget.clamp(-0.92, 0.92).toDouble() : 0.0;
    return Offset(x, _playerAimDepth('DRIVE', -0.75));
  }

  double get playerAimScatter => _isAimingSideways ? _aimScatter : 0.15;

  bool get showAimPreview =>
      !isGameOver &&
      ((phase == RallyPhase.readyToServe && isPlayerServing) ||
          ballInPlayerReach);

  void triggerAttack(String shotType) {
    if (isGameOver) return;
    if (phase == RallyPhase.readyToServe && isPlayerServing) {
      _executePlayerServe();
      return;
    }

    // Can't swing again until the last swing is mostly done (no button-mashing)
    if (_playerSwingCooldown > 0) return;

    final CharacterAnimState swingAnim = _animStateForShot(shotType);

    // Only a ball coming toward you (not your own shot) can be hit
    final bool ballIsHittable =
        phase != RallyPhase.readyToServe && !_lastHitByPlayer && ballY > -0.05;

    String? failText;
    if (ballIsHittable) {
      final double dist =
          sqrt(pow(ballX - playerX, 2) + pow(ballY - playerY, 2));
      final bool isSmash = shotType == 'SMASH';
      final double maxH = isSmash
          ? 1.20
          : (shotType == 'ROLL' || shotType == 'SLICE')
              ? 0.60
              : (shotType == 'LOB' ? 0.70 : 0.85);
      final double minH = isSmash ? 0.45 : 0.0;

      if (dist > playerReach) {
        failText = 'TOO FAR!';
      } else if (ballHeight > maxH) {
        failText = 'TOO HIGH!';
      } else if (ballHeight < minH) {
        failText = 'TOO LOW!';
      } else {
        _executePlayerHit(shotType);
        return;
      }
    }

    // Whiff: the player still swings, but the ball is untouched
    _startPlayerAnim(swingAnim);
    _playerSwingCooldown = playerAnimDuration * 0.7;
    if (failText != null) {
      timingFeedback = failText;
      _clearTimingFeedback();
    }
  }

  CharacterAnimState _animStateForShot(String shotType) {
    switch (shotType) {
      case 'SMASH':
      case 'ULTIMATE':
        return CharacterAnimState.smash;
      case 'ROLL':
      case 'SLICE':
        return CharacterAnimState.slice;
      case 'LOB':
        return CharacterAnimState.lob;
      default:
        return CharacterAnimState.drive;
    }
  }

  double _animDurationFor(CharacterAnimState s) {
    switch (s) {
      case CharacterAnimState.serving:
        return 0.60;
      case CharacterAnimState.smash:
        return 0.55;
      case CharacterAnimState.lob:
        return 0.55;
      case CharacterAnimState.slice:
        return 0.48;
      case CharacterAnimState.drive:
        return 0.42;
      default:
        return 0.40;
    }
  }

  void _startPlayerAnim(CharacterAnimState s) {
    playerAnimState = s;
    playerAnimDuration = _animDurationFor(s);
    playerAnimTimer = playerAnimDuration;
  }

  void _startAiAnim(CharacterAnimState s) {
    aiAnimState = s;
    aiAnimDuration = _animDurationFor(s);
    aiAnimTimer = aiAnimDuration;
  }

  /// Called whenever the human hits/serves: the AI needs a moment to react.
  void _onPlayerShot() {
    _aiReactTimer = _aiReactTime;
    _aiAimErrX = (_rng.nextDouble() - 0.5) * 2.0 * _aiTrackError;
  }

  void _executePlayerServe() {
    phase = RallyPhase.inFlight;
    _bounceCount = 0;
    _currentRallyHits = 1;
    if (_currentRallyHits > longestRally) {
      longestRally = _currentRallyHits;
    }
    ballX = playerX;
    ballY = playerY;
    ballHeight = 0.45;
    _lastHitByPlayer = true;
    _isServeInFlight = true;

    _launchBall(
      targetX: _playerServeAimX(),
      targetY: -0.65,
      airTime: 0.95,
      spin: 0.0,
    );

    _startPlayerAnim(CharacterAnimState.serving);
    _onPlayerShot();

    matchStatus = 'SERVE IN PLAY';
    timingFeedback = 'STREET SERVE!';
    AudioService.playShotSfx('DRIVE');
    _clearTimingFeedback();
  }

  void _executePlayerHit(String shotType) {
    // Kitchen fault = volleying while standing in the kitchen
    if (playerY < 0.32 && ballHeight > 0.20 && _bounceCount == 0) {
      kitchenFaults++;
      _currentRallyHits = 0;
      matchStatus = 'KITCHEN FAULT! POINT TO AI';
      AudioService.playFaultSfx();
      _awardPointToOpponent();
      return;
    }

    phase = RallyPhase.activeRally;
    _bounceCount = 0;
    _currentRallyHits++;
    if (_currentRallyHits > longestRally) {
      longestRally = _currentRallyHits;
    }
    if (shotType == 'SMASH' || shotType == 'ULTIMATE') {
      smashesLanded++;
    }

    _lastHitByPlayer = true;
    _isServeInFlight = false;

    if (!isUltimateActive) {
      ultimateGauge = (ultimateGauge + 0.20).clamp(0.0, 1.0);
    }

    // Aim: hold the stick left/right (side) and up/down (deeper/shorter)
    // when you hit. Sloppier paddles scatter the shot a little more.
    double targetX = _playerAimX();
    double targetY = -0.72;
    double airTime = 0.80;
    double spin = 0.35; // + topspin, - backspin

    if (shotType == 'ULTIMATE' || isUltimateActive) {
      isUltimateActive = true;
      targetY = -0.85;
      airTime = 0.55;
      spin = 0.8;
      playerAnimState = CharacterAnimState.smash;
      timingFeedback = '  STREET OVERDRIVE!';
      AudioService.playShotSfx('SMASH');
    } else {
      switch (shotType) {
        case 'SMASH':
          targetY = -0.80;
          airTime = 0.60;
          spin = 0.7;
          playerAnimState = CharacterAnimState.smash;
          timingFeedback = 'STREET SLAM!';
          break;
        case 'SPEED_UP':
          targetY = -0.65;
          airTime = 0.70;
          spin = 0.45;
          playerAnimState = CharacterAnimState.drive;
          timingFeedback = 'TURBO SPEED!';
          break;
        case 'ROLL':
          targetY = -0.28;
          airTime = 0.85;
          spin = 0.9; // heavy topspin: arcs up, dips fast, kicks forward
          playerAnimState = CharacterAnimState.slice;
          timingFeedback = 'ALLEY DINK!';
          break;
        case 'SLICE':
          targetY = -0.28;
          airTime = 0.85;
          spin = -0.8; // backspin: floats, dies on the bounce
          playerAnimState = CharacterAnimState.slice;
          timingFeedback = 'ALLEY DINK!';
          break;
        case 'LOB':
          targetY = -0.85;
          airTime = 1.15;
          spin = 0.3;
          playerAnimState = CharacterAnimState.lob;
          timingFeedback = 'SKY LOB!';
          break;
        case 'DRIVE':
        default:
          targetY = -0.75;
          airTime = 0.80;
          spin = 0.35;
          playerAnimState = CharacterAnimState.drive;
          timingFeedback = 'CLEAN DRIVE!';
          break;
      }
      AudioService.playShotSfx(shotType);
    }

    // Paddle stats: power = faster shots, spin = more spin.
    airTime /= (1.0 + (paddle.power - 45) / 250.0);
    spin *= (paddle.spin / 60.0);

    targetY = _playerAimDepth(shotType, targetY);

    _startPlayerAnim(playerAnimState);
    _playerSwingCooldown = playerAnimDuration * 0.6;
    _onPlayerShot();

    _launchBall(
      targetX: targetX,
      targetY: targetY,
      airTime: airTime,
      spin: spin,
    );

    matchStatus = 'RALLY IN PROGRESS';
    _clearTimingFeedback();
  }

  /// Launches the ball from its current position so that, with drag and spin
  /// included, it lands on ([targetX], [targetY]) after [airTime] seconds.
  /// If the arc would clip the net, the flight is lengthened until it clears.
  void _launchBall({
    required double targetX,
    required double targetY,
    required double airTime,
    double spin = 0.0,
    bool assistNet = true,
  }) {
    const double k = airDrag;
    final double s = spin.clamp(-1.0, 1.0).toDouble();
    final double dx = targetX - ballX;
    final double dy = targetY - ballY;
    final bool crossesNet = ballY * targetY < 0;

    double t = airTime;
    double vx = 0, vy = 0, vz = 0, gEff = gravity;

    for (int i = 0; i < 12; i++) {
      final double decay = 1.0 - exp(-k * t);
      vx = dx * k / decay;
      vy = dy * k / decay;
      final double speed = sqrt(vx * vx + vy * vy);
      gEff = max(gravity + s * spinMagnus * speed, 3.0);
      vz = (gEff * t / k - ballHeight) * k / decay - gEff / k;

      if (!crossesNet || !assistNet) break;

      final double arg = 1.0 + ballY * k / vy;
      if (arg <= 0) break;
      final double tn = -log(arg) / k; // time the ball reaches the net
      final double hn = ballHeight +
          (vz + gEff / k) * (1.0 - exp(-k * tn)) / k -
          gEff * tn / k;

      if (hn >= netHeight + netClearance) break;
      t += 0.05; // arc too flat: give it more air time
    }

    ballVx = vx;
    ballVy = vy;
    ballVz = vz;
    ballSpin = s;
    _gEff = gEff;
    ballImpactTimer = 0.10;
  }

  void _clearTimingFeedback() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      timingFeedback = null;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    if (phase == RallyPhase.readyToServe) {
      _snapBallToServerHand();
    }

    if (_aiShrinkTimer > 0) _aiShrinkTimer -= dt;
    animClock += dt;

    if (_playerSwingCooldown > 0) _playerSwingCooldown -= dt;

    // Player Movement & Animation Cycle
    double moveSpeed = 1.4 * characterStyle.speedMultiplier;
    if (playerInputDir != Offset.zero) {
      playerX =
          (playerX + playerInputDir.dx * moveSpeed * dt).clamp(-0.92, 0.92);
      playerY =
          (playerY + playerInputDir.dy * moveSpeed * dt).clamp(0.20, 0.92);

      if (playerAnimTimer <= 0) {
        if (playerInputDir.dy < -0.3) {
          playerAnimState = CharacterAnimState.walkingUp;
        } else if (playerInputDir.dy > 0.3) {
          playerAnimState = CharacterAnimState.walkingDown;
        } else if (playerInputDir.dx < -0.3) {
          playerAnimState = CharacterAnimState.walkingLeft;
        } else if (playerInputDir.dx > 0.3) {
          playerAnimState = CharacterAnimState.walkingRight;
        }
      }

      playerStepTimer += dt;
      playerWalkPhase += dt * 11.0;
      if (playerStepTimer > 0.12) {
        playerFrame = (playerFrame + 1) % 4;
        playerStepTimer = 0.0;
      }
    } else if (playerAnimTimer <= 0) {
      playerAnimState = CharacterAnimState.idle;
      playerFrame = 0;
    }

    if (playerAnimTimer > 0) playerAnimTimer -= dt;
    if (aiAnimTimer > 0) aiAnimTimer -= dt;

    // Power Orb Spawning
    if (phase == RallyPhase.activeRally && orbX == null) {
      _orbSpawnTimer += dt;
      if (_orbSpawnTimer > 4.0) {
        _orbSpawnTimer = 0.0;
        orbX = (Random().nextDouble() - 0.5) * 1.0;
        orbY = -0.10 + Random().nextDouble() * 0.20;
        orbType = OrbType.values[Random().nextInt(OrbType.values.length)];
      }
    }

    // AI Serve Trigger
    if (phase == RallyPhase.readyToServe && !isPlayerServing) {
      _aiServeTimer += dt;
      if (_aiServeTimer > 1.0) {
        _aiServeTimer = 0.0;
        _executeAiServe();
      }
    }

    // Ball Dynamics (fixed sub-steps => same feel at any frame rate)
    if (phase != RallyPhase.readyToServe) {
      double remaining = min(dt, 0.05);
      while (remaining > 0) {
        final double step = min(remaining, _physicsStep);
        remaining -= step;
        if (!_stepBall(step)) return; // rally ended, state already reset
      }

      _updateAiBehavior(dt);
      if (isGameOver) return;

      if (phase != RallyPhase.readyToServe) {
        _recordTrail();
        final double speed = sqrt(ballVx * ballVx + ballVy * ballVy);
        ballRotation += (2.0 + ballSpin * 16.0 + speed * 3.0) * dt;

        if (ballY > 1.10) {
          matchStatus = 'POINT TO AI!';
          AudioService.playFaultSfx();
          _awardPointToOpponent();
        }
      }
    } else {
      trail.clear();
    }

    if (ballImpactTimer > 0) ballImpactTimer -= dt;

    _notifyState();
  }

  void _recordTrail() {
    trail.add(BallTrailPoint(ballX, ballY, ballHeight));
    if (trail.length > 9) trail.removeAt(0);
  }

  /// Advances the ball by [dt]. Returns false if the rally ended this step.
  bool _stepBall(double dt) {
    const double k = airDrag;
    final double f = exp(-k * dt);
    final double prevY = ballY;

    // Exact exponential-drag integration over this step.
    ballX += ballVx * (1.0 - f) / k;
    ballY += ballVy * (1.0 - f) / k;
    ballHeight += (ballVz + _gEff / k) * (1.0 - f) / k - _gEff * dt / k;

    ballVx *= f;
    ballVy *= f;
    ballVz = ballVz * f - _gEff * (1.0 - f) / k;

    // Net: the ball must pass over it
    if (prevY * ballY < 0 && ballHeight < netHeight) {
      if (_lastHitByPlayer) {
        matchStatus = 'NET! POINT TO AI';
        AudioService.playFaultSfx();
        _awardPointToOpponent();
      } else {
        matchStatus = 'AI NET! YOUR POINT';
        AudioService.playShotSfx('DRIVE');
        _awardPointToPlayer();
      }
      return false;
    }

    // Power orb pickup
    if (orbX != null && orbY != null) {
      final double distToOrb =
          sqrt(pow(ballX - orbX!, 2) + pow(ballY - orbY!, 2));
      if (distToOrb < 0.22) {
        _activateOrbPower(orbType!);
        orbX = null;
        orbY = null;
        orbType = null;
      }
    }

    // Bounce
    if (ballHeight <= 0.0 && ballVz < 0) {
      ballHeight = 0.0;
      _bounceCount++;
      ballImpactTimer = 0.12;

      if (_bounceCount == 1) {
        final bool outOfBounds = ballX.abs() > 1.02 || ballY.abs() > 1.02;
        // A shot must land on the OTHER side of the net
        final bool wrongSide = _lastHitByPlayer ? ballY > 0.0 : ballY < 0.0;
        // A serve must clear the kitchen
        final bool shortServe = _isServeInFlight && ballY.abs() < 0.32;

        if (outOfBounds || wrongSide || shortServe) {
          if (_lastHitByPlayer) {
            matchStatus = outOfBounds
                ? 'OUT! POINT TO AI'
                : (shortServe
                    ? 'SERVE FAULT! POINT TO AI'
                    : 'NET SIDE! POINT TO AI');
            AudioService.playFaultSfx();
            _awardPointToOpponent();
          } else {
            matchStatus = outOfBounds
                ? 'OUT! YOUR POINT'
                : (shortServe
                    ? 'AI SERVE FAULT! YOUR POINT'
                    : 'AI SHORT! YOUR POINT');
            AudioService.playShotSfx('DRIVE');
            _awardPointToPlayer();
          }
          return false;
        }
      } else {
        // Only ONE bounce is allowed per side
        if (ballY > 0) {
          matchStatus = 'DOUBLE BOUNCE! POINT TO AI';
          AudioService.playFaultSfx();
          _awardPointToOpponent();
        } else {
          matchStatus = 'DOUBLE BOUNCE! YOUR POINT';
          AudioService.playShotSfx('DRIVE');
          _awardPointToPlayer();
        }
        return false;
      }

      // Legal bounce: spin changes how the ball comes off the court.
      // Topspin = lower bounce + kicks forward. Backspin = higher, grabs and slows.
      final double s = ballSpin;
      final double vertKeep =
          (bounceRestitution * (1.0 - 0.18 * s)).clamp(0.35, 0.85).toDouble();
      final double horizKeep =
          (bounceFriction * (1.0 + 0.22 * s)).clamp(0.45, 1.05).toDouble();

      ballVz = -ballVz * vertKeep;
      ballVx *= horizKeep;
      ballVy *= horizKeep;
      _gEff = gravity + (_gEff - gravity) * 0.4;
      ballSpin *= 0.4;
    }

    return true;
  }

  void _activateOrbPower(OrbType type) {
    AudioService.playShotSfx('SMASH');
    switch (type) {
      case OrbType.speedDemon:
        ballVx *= 1.35;
        ballVy *= 1.35;
        timingFeedback = '  SPEED DEMON ORB!';
        break;
      case OrbType.shrinkRay:
        _aiShrinkTimer = 5.0;
        timingFeedback = '  AI PADDLE SHRUNK!';
        break;
      case OrbType.doublePoints:
        isDoublePointsActive = true;
        timingFeedback = '  DOUBLE POINTS RALLY!';
        break;
    }
    _clearTimingFeedback();
  }

  void _executeAiServe() {
    phase = RallyPhase.inFlight;
    _bounceCount = 0;
    _currentRallyHits = 1;
    if (_currentRallyHits > longestRally) {
      longestRally = _currentRallyHits;
    }
    ballX = opponentX;
    ballY = opponentY;
    ballHeight = 0.45;
    _lastHitByPlayer = false;
    _isServeInFlight = true;

    _launchBall(
      targetX: playerX * 0.4 + (Random().nextDouble() - 0.5) * 0.3,
      targetY: 0.65,
      airTime: 0.95,
      spin: 0.0,
    );

    _startAiAnim(CharacterAnimState.serving);
    matchStatus = 'AI SERVED - RETURN IT!';
    AudioService.playShotSfx('DRIVE');
  }

  /// Where the AI wants to stand when it has nothing urgent to do.
  double _aiHomeY() {
    final double s = _aiSkill;
    double lerp(double a, double b) => a + (b - a) * s;
    switch (_aiLastShot) {
      case 'DINK':
        return -lerp(
            0.50, 0.38); // followed its dink in: crowd the kitchen line
      case 'LOB':
        return -0.82; // hit a lob: drop back
      case 'SMASH':
        return -lerp(0.58, 0.44);
      case 'SPEED_UP':
        return -lerp(0.62, 0.46);
      default:
        // Rookie hangs back; Titan camps near the kitchen line
        return playerY < 0.50 ? -lerp(0.58, 0.42) : -lerp(0.74, 0.48);
    }
  }

  /// Simulates the ball forward (same physics) to find its first bounce.
  List<double> _predictLanding() {
    const double k = airDrag;
    const double dt = 1 / 60;
    final double f = exp(-k * dt);

    double x = ballX, y = ballY, h = ballHeight;
    double vx = ballVx, vy = ballVy, vz = ballVz;

    for (int i = 0; i < 240; i++) {
      x += vx * (1.0 - f) / k;
      y += vy * (1.0 - f) / k;
      h += (vz + _gEff / k) * (1.0 - f) / k - _gEff * dt / k;
      vx *= f;
      vy *= f;
      vz = vz * f - _gEff * (1.0 - f) / k;

      if (h <= 0 && vz < 0) break;
    }
    return [x, y];
  }

  void _updateAiBehavior(double dt) {
    final double aiSpeed = _aiTopSpeed;
    if (_aiReactTimer > 0) _aiReactTimer -= dt;

    final double incomingSpeed = sqrt(ballVx * ballVx + ballVy * ballVy);

    // ---- 1. Decide where to stand (both axes) ----
    double targetX = opponentX;
    double targetY = _aiHomeY();

    if (ballVy < 0) {
      if (_aiReactTimer > 0) {
        // Still reading the shot: drift toward the middle
        targetX = 0.0;
      } else if (_bounceCount == 0) {
        // Ball still in the air: get to where it will land, a step behind it,
        // so short balls pull the AI forward and deep balls push it back.
        final List<double> land = _predictLanding();
        targetX = land[0] + _aiAimErrX;
        targetY = (land[1] - (0.08 + 0.09 * incomingSpeed))
            .clamp(-0.92, -0.34)
            .toDouble();
      } else {
        // Ball has bounced: chase it, even into the kitchen (legal after a bounce)
        targetX = ballX + ballVx * 0.20 + _aiAimErrX * 0.3;
        targetY = (ballY + ballVy * 0.20).clamp(-0.92, -0.14).toDouble();
      }
    } else {
      // Ball heading to the player: recover toward the middle
      targetX = playerX * 0.35;
    }

    // ---- 2. Move with acceleration (smooth, not instant) ----
    final double dx = targetX - opponentX;
    final double dy = targetY - opponentY;
    final double dist = sqrt(dx * dx + dy * dy);

    double wantVx = 0.0, wantVy = 0.0;
    if (dist > 0.03) {
      final double sp = min(aiSpeed, dist / 0.12);
      wantVx = dx / dist * sp;
      wantVy = dy / dist * sp;
    }

    final double ease = min(1.0, 10.0 * dt);
    aiVelX += (wantVx - aiVelX) * ease;
    aiVelY += (wantVy - aiVelY) * ease;

    opponentX = (opponentX + aiVelX * dt).clamp(-0.92, 0.92).toDouble();
    opponentY = (opponentY + aiVelY * dt).clamp(-0.92, -0.10).toDouble();

    // ---- 3. Run animation (direction + speed based) ----
    final double moveAmt = aiMoveAmount;
    if (aiAnimTimer <= 0) {
      if (moveAmt > 0.08) {
        if (aiVelY.abs() >= aiVelX.abs()) {
          aiAnimState = aiVelY < 0
              ? CharacterAnimState.walkingUp
              : CharacterAnimState.walkingDown;
        } else {
          aiAnimState = aiVelX < 0
              ? CharacterAnimState.walkingLeft
              : CharacterAnimState.walkingRight;
        }
        aiWalkPhase += dt * (6.0 + 8.0 * moveAmt);
        aiStepTimer += dt;
        if (aiStepTimer > 0.12) {
          aiFrame = (aiFrame + 1) % 4;
          aiStepTimer = 0.0;
        }
      } else {
        aiAnimState = CharacterAnimState.idle;
        aiFrame = 0;
      }
    }

    // ---- 4. Hit detection: real 2D reach, not just left/right ----
    // The AI plays off the bounce, and only volleys when it is up at the net.
    // Only Rookies are careless enough to volley from inside the kitchen.
    final bool kitchenOk = opponentY <= -0.34 || aiDupr < 3.0;
    final bool canVolley = kitchenOk && opponentY > -0.55 && ballHeight < 0.80;

    if (ballVy < 0 &&
        ballY < -0.02 &&
        ballHeight < 1.10 &&
        (_bounceCount >= 1 || canVolley)) {
      double reach = _aiReach;
      if (_aiShrinkTimer > 0) reach *= 0.50;

      final double d =
          sqrt(pow(ballX - opponentX, 2) + pow(ballY - opponentY, 2));
      if (d <= reach) {
        _aiExecuteHit(d, reach, incomingSpeed);
        return;
      }
    }

    if (ballY < -1.08 && ballVy < 0) {
      matchStatus = 'YOUR POINT!';
      AudioService.playShotSfx('DRIVE');
      _awardPointToPlayer();
    }
  }

  void _aiExecuteHit(double dist, double reach, double incomingSpeed) {
    // Volleying from inside the kitchen is a fault
    if (opponentY > -0.32 && _bounceCount == 0 && ballHeight > 0.15) {
      matchStatus = 'AI KITCHEN FAULT! YOUR POINT';
      AudioService.playFaultSfx();
      _awardPointToPlayer();
      return;
    }

    _bounceCount = 0;
    _currentRallyHits++;
    if (_currentRallyHits > longestRally) {
      longestRally = _currentRallyHits;
    }

    phase = RallyPhase.activeRally;
    isUltimateActive = false;
    _lastHitByPlayer = false;
    _isServeInFlight = false;

    // ---- Can the AI make a clean shot? Harder balls / stretched = more errors
    final double pressure =
        ((incomingSpeed - 1.6) / 1.6).clamp(0.0, 1.0).toDouble();
    final double stretch = aiMoveAmount; // running flat-out = harder to control
    final double baseMiss = _aiBaseMiss;
    final double missChance =
        (baseMiss + 0.14 * pressure + 0.14 * stretch * stretch)
            .clamp(0.0, 0.75)
            .toDouble();

    // ---- Shot selection (varies with situation and skill) ----
    final double r = _rng.nextDouble();
    final bool nearNet = opponentY > -0.50;
    final bool highBall = ballHeight > 0.60;
    final bool playerAtNet = playerY < 0.50;

    String shot;
    if (highBall && (aiDupr >= 3.0 || r < 0.5)) {
      shot = 'SMASH';
    } else if (nearNet) {
      final double dinkP = 0.35 + 0.40 * _aiSkill; // Titan dinks the most
      shot = r < dinkP ? 'DINK' : (r < 0.85 ? 'DRIVE' : 'SPEED_UP');
    } else if (playerAtNet && r < 0.35) {
      shot = 'LOB';
    } else if (r < 0.14) {
      shot = 'DINK';
    } else if (r < 0.36) {
      shot = 'SPEED_UP';
    } else {
      shot = 'DRIVE';
    }

    // ---- Placement: better players aim away from you ----
    double targetX;
    if (_rng.nextDouble() < _aiPlacement) {
      final double away =
          playerX.abs() < 0.08 ? (_rng.nextBool() ? 1.0 : -1.0) : -playerX.sign;
      targetX = away * (0.30 + _rng.nextDouble() * 0.45);
    } else {
      targetX = (_rng.nextDouble() - 0.5) * 0.6;
    }

    double targetY = 0.72;
    double airTime = 0.80;
    double spin = 0.35;
    CharacterAnimState anim = CharacterAnimState.drive;

    switch (shot) {
      case 'SMASH':
        targetY = 0.82;
        airTime = 0.60;
        spin = 0.7;
        anim = CharacterAnimState.smash;
        break;
      case 'SPEED_UP':
        targetY = 0.68;
        airTime = 0.68;
        spin = 0.45;
        anim = CharacterAnimState.drive;
        break;
      case 'DINK':
        targetY = 0.18 + _rng.nextDouble() * 0.08;
        airTime = 0.85;
        spin = -0.7;
        anim = CharacterAnimState.slice;
        break;
      case 'LOB':
        targetY = 0.85;
        airTime = 1.15;
        spin = 0.3;
        anim = CharacterAnimState.lob;
        break;
      default:
        break;
    }

    airTime *= _aiShotTimeScale; // Rookie = slower shots, Titan = faster

    // ---- Unforced error: hits long, wide, or into the net ----
    bool netError = false;
    if (_rng.nextDouble() < missChance) {
      final int kind = _rng.nextInt(3);
      if (kind == 0) {
        targetY = 1.12 + _rng.nextDouble() * 0.10; // long
      } else if (kind == 1) {
        targetX = (targetX >= 0 ? 1.0 : -1.0) *
            (1.12 + _rng.nextDouble() * 0.12); // wide
      } else {
        netError = true; // too flat
      }
    }

    _startAiAnim(anim);
    _aiLastShot = shot;

    _launchBall(
      targetX: targetX,
      targetY: targetY,
      airTime: airTime,
      spin: spin,
      assistNet: !netError,
    );

    if (netError) ballVz *= 0.45;

    matchStatus = 'RALLY IN PROGRESS';
    AudioService.playShotSfx(shot == 'SMASH' ? 'SMASH' : 'DRIVE');
  }

  void _awardPointToPlayer() {
    int pointsEarned = isDoublePointsActive ? 2 : 1;
    playerScore += pointsEarned;
    isDoublePointsActive = false;

    if (playerScore >= targetScore && (playerScore - opponentScore) >= 2) {
      isGameOver = true;
      matchStatus = 'MATCH OVER! YOU WIN!';
      _notifyState();
    } else {
      resetPositions(isPlayerServing: true);
    }
  }

  void _awardPointToOpponent() {
    int pointsEarned = isDoublePointsActive ? 2 : 1;
    opponentScore += pointsEarned;
    isDoublePointsActive = false;

    if (opponentScore >= targetScore && (opponentScore - playerScore) >= 2) {
      isGameOver = true;
      matchStatus = 'MATCH OVER! AI WINS!';
      _notifyState();
    } else {
      resetPositions(isPlayerServing: false);
    }
  }

  void _notifyState() {
    onStateUpdate(
      playerScore: playerScore,
      opponentScore: opponentScore,
      isPlayerServing: isPlayerServing,
      matchStatus: matchStatus,
      isGameOver: isGameOver,
      ballX: ballX,
      ballY: ballY,
      ballHeight: ballHeight,
      playerX: playerX,
      playerY: playerY,
      opponentX: opponentX,
      opponentY: opponentY,
      ultimateGauge: ultimateGauge,
      isUltimateActive: isUltimateActive,
      orbX: orbX,
      orbY: orbY,
      orbType: orbType,
      isDoublePointsActive: isDoublePointsActive,
      isAiShrunk: _aiShrinkTimer > 0,
      timingFeedback: timingFeedback,
      playerAnimState: playerAnimState,
      aiAnimState: aiAnimState,
      playerFrame: playerFrame,
      aiFrame: aiFrame,
    );
  }
}
