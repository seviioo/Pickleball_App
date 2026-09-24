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

  static const double gravity = 3.5;

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

  void triggerAttack(String shotType) {
    if (isGameOver) return;

    if (phase == RallyPhase.readyToServe && isPlayerServing) {
      _executePlayerServe();
      return;
    }

    if (ballVy > 0 || ballY > -0.2) {
      double dist = sqrt(pow(ballX - playerX, 2) + pow(ballY - playerY, 2));
      if (dist <= 0.65) {
        _executePlayerHit(shotType);
      } else {
        timingFeedback = 'TOO FAR!';
        _clearTimingFeedback();
      }
    }
  }

  void _executePlayerServe() {
    phase = RallyPhase.inFlight;
    _bounceCount = 0;

    ballX = playerX;
    ballY = playerY;
    ballHeight = 0.45;

    double targetX = (Random().nextDouble() - 0.5) * 0.5;
    double targetY = -0.65;
    double airTime = 1.35;

    ballVx = (targetX - playerX) / airTime;
    ballVy = (targetY - playerY) / airTime;
    ballVz = 0.5 * gravity * airTime;

    playerAnimState = CharacterAnimState.serving;
    playerAnimTimer = 0.35;

    matchStatus = 'SERVE IN PLAY';
    timingFeedback = 'STREET SERVE!';
    AudioService.playShotSfx('DRIVE');
    _clearTimingFeedback();
  }

  void _executePlayerHit(String shotType) {
    if (playerY < 0.32 && ballHeight > 0.20) {
      matchStatus = 'KITCHEN FAULT! POINT TO AI';
      AudioService.playFaultSfx();
      _awardPointToOpponent();
      return;
    }

    phase = RallyPhase.activeRally;
    _bounceCount = 0;

    if (!isUltimateActive) {
      ultimateGauge = (ultimateGauge + 0.20).clamp(0.0, 1.0);
    }

    double targetX = (Random().nextDouble() - 0.5) * 0.7;
    double targetY = -0.72;
    double airTime = 1.30;

    if (shotType == 'ULTIMATE' || isUltimateActive) {
      isUltimateActive = true;
      targetY = -0.85;
      airTime = 0.85;
      playerAnimState = CharacterAnimState.smash;
      timingFeedback = '⚡ STREET OVERDRIVE!';
      AudioService.playShotSfx('SMASH');
    } else {
      switch (shotType) {
        case 'SMASH':
          targetY = -0.80;
          airTime = 1.00;
          playerAnimState = CharacterAnimState.smash;
          timingFeedback = 'STREET SLAM!';
          break;
        case 'SPEED_UP':
          targetY = -0.65;
          airTime = 1.15;
          playerAnimState = CharacterAnimState.drive;
          timingFeedback = 'TURBO SPEED!';
          break;
        case 'ROLL':
        case 'SLICE':
          targetY = -0.28;
          airTime = 1.45;
          playerAnimState = CharacterAnimState.slice;
          timingFeedback = 'ALLEY DINK!';
          break;
        case 'LOB':
          targetY = -0.85;
          airTime = 1.50;
          playerAnimState = CharacterAnimState.lob;
          timingFeedback = 'SKY LOB!';
          break;
        case 'DRIVE':
        default:
          targetY = -0.75;
          airTime = 1.30;
          playerAnimState = CharacterAnimState.drive;
          timingFeedback = 'CLEAN DRIVE!';
          break;
      }
      AudioService.playShotSfx(shotType);
    }

    playerAnimTimer = 0.35;
    ballVx = (targetX - ballX) / airTime;
    ballVy = (targetY - ballY) / airTime;
    ballVz = 0.5 * gravity * airTime;

    matchStatus = 'RALLY IN PROGRESS';
    _clearTimingFeedback();
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

    // Ball Dynamics
    if (phase != RallyPhase.readyToServe) {
      ballX += ballVx * dt;
      ballY += ballVy * dt;
      ballHeight += ballVz * dt;
      ballVz -= gravity * dt;

      if (orbX != null && orbY != null) {
        double distToOrb = sqrt(pow(ballX - orbX!, 2) + pow(ballY - orbY!, 2));
        if (distToOrb < 0.22) {
          _activateOrbPower(orbType!);
          orbX = null;
          orbY = null;
          orbType = null;
        }
      }

      if (ballHeight <= 0.0) {
        ballHeight = 0.0;
        ballVz = -ballVz * 0.45;
        _bounceCount++;

        if (_bounceCount == 1) {
          if (ballX.abs() > 1.02 || ballY.abs() > 1.02) {
            if (ballVy < 0) {
              matchStatus = 'OUT! POINT TO AI';
              AudioService.playFaultSfx();
              _awardPointToOpponent();
            } else {
              matchStatus = 'OUT! YOUR POINT';
              AudioService.playShotSfx('DRIVE');
              _awardPointToPlayer();
            }
            return;
          }
        } else if (_bounceCount >= 2) {
          if (ballY > 0) {
            matchStatus = 'DOUBLE BOUNCE! POINT TO AI';
            AudioService.playFaultSfx();
            _awardPointToOpponent();
          } else {
            matchStatus = 'DOUBLE BOUNCE! YOUR POINT';
            AudioService.playShotSfx('DRIVE');
            _awardPointToPlayer();
          }
          return;
        }
      }

      _updateAiBehavior(dt);

      if (ballY > 1.10) {
        matchStatus = 'POINT TO AI!';
        AudioService.playFaultSfx();
        _awardPointToOpponent();
      }
    }

    _notifyState();
  }

  void _activateOrbPower(OrbType type) {
    AudioService.playShotSfx('SMASH');
    switch (type) {
      case OrbType.speedDemon:
        ballVx *= 1.35;
        ballVy *= 1.35;
        timingFeedback = '⚡ SPEED DEMON ORB!';
        break;
      case OrbType.shrinkRay:
        _aiShrinkTimer = 5.0;
        timingFeedback = '🌀 AI PADDLE SHRUNK!';
        break;
      case OrbType.doublePoints:
        isDoublePointsActive = true;
        timingFeedback = '💰 DOUBLE POINTS RALLY!';
        break;
    }
    _clearTimingFeedback();
  }

  void _executeAiServe() {
    phase = RallyPhase.inFlight;
    _bounceCount = 0;

    ballX = opponentX;
    ballY = opponentY;
    ballHeight = 0.45;

    double targetX = playerX * 0.4 + (Random().nextDouble() - 0.5) * 0.3;
    double targetY = 0.65;
    double airTime = 1.35;

    ballVx = (targetX - opponentX) / airTime;
    ballVy = (targetY - opponentY) / airTime;
    ballVz = 0.5 * gravity * airTime;

    aiAnimState = CharacterAnimState.serving;
    aiAnimTimer = 0.35;

    matchStatus = 'AI SERVED - RETURN IT!';
    AudioService.playShotSfx('DRIVE');
  }

  void _updateAiBehavior(double dt) {
    double aiSpeed = 0.90 + (aiDupr / 5.0) * 0.45;
    double oldX = opponentX;
    double oldY = opponentY;

    // Dynamic 2-Axis Tracking (X & Y Axis Movement)
    if (ballX > opponentX + 0.04) {
      opponentX = (opponentX + aiSpeed * dt).clamp(-0.92, 0.92);
    } else if (ballX < opponentX - 0.04) {
      opponentX = (opponentX - aiSpeed * dt).clamp(-0.92, 0.92);
    }

    // Dynamic Depth Logic: Advance for dinks/short balls, retreat for lobs
    double targetY = -0.75;
    if (ballVy < 0) {
      if (ballVz > 0.8 || ballHeight > 0.65) {
        targetY = -0.88; // Retreat to baseline
      } else if (ballY > -0.35) {
        targetY = -0.35; // Advance to kitchen line
      } else {
        targetY = -0.65;
      }
    }

    if (opponentY < targetY - 0.03) {
      opponentY = (opponentY + aiSpeed * 0.85 * dt).clamp(-0.92, -0.30);
    } else if (opponentY > targetY + 0.03) {
      opponentY = (opponentY - aiSpeed * 0.85 * dt).clamp(-0.92, -0.30);
    }

    // AI Directional Animation Cycling
    if (aiAnimTimer <= 0) {
      double dx = opponentX - oldX;
      double dy = opponentY - oldY;

      if (dx.abs() > 0.001 || dy.abs() > 0.001) {
        if (dy < -0.001) {
          aiAnimState = CharacterAnimState.walkingUp;
        } else if (dy > 0.001) {
          aiAnimState = CharacterAnimState.walkingDown;
        } else if (dx < -0.001) {
          aiAnimState = CharacterAnimState.walkingLeft;
        } else {
          aiAnimState = CharacterAnimState.walkingRight;
        }

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

    // AI Hit & Kitchen Fault Detection
    if (ballVy < 0 && ballY <= opponentY + 0.20 && ballY >= opponentY - 0.20) {
      double reach = 0.60 + (aiDupr / 5.0) * 0.15;
      if (_aiShrinkTimer > 0) reach *= 0.50;

      if ((ballX - opponentX).abs() <= reach) {
        // AI Non-Volley Zone (Kitchen) Fault Enforcement
        if (opponentY > -0.32 && ballHeight > 0.15) {
          matchStatus = 'AI KITCHEN FAULT! YOUR POINT';
          AudioService.playFaultSfx();
          _awardPointToPlayer();
          return;
        }

        _bounceCount = 0;
        phase = RallyPhase.activeRally;
        isUltimateActive = false;

        double targetX = playerX * 0.5 + (Random().nextDouble() - 0.5) * 0.4;
        double targetY = 0.72;
        double airTime = 1.30;

        if (opponentY > -0.45) {
          aiAnimState = CharacterAnimState.slice;
        } else if (ballHeight > 0.5) {
          aiAnimState = CharacterAnimState.smash;
          targetY = 0.82;
          airTime = 0.95;
        } else {
          aiAnimState = CharacterAnimState.drive;
        }
        aiAnimTimer = 0.35;

        ballVx = (targetX - ballX) / airTime;
        ballVy = (targetY - ballY) / airTime;
        ballVz = 0.5 * gravity * airTime;

        matchStatus = 'RALLY IN PROGRESS';
        AudioService.playShotSfx('DRIVE');
      } else if (ballY < -1.08) {
        matchStatus = 'YOUR POINT!';
        AudioService.playShotSfx('DRIVE');
        _awardPointToPlayer();
      }
    }
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
