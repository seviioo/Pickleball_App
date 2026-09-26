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
  double? aimTargetX,
  double? aimTargetY,
  required bool isAiming,
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

  // Aiming State Variables
  double? aimTargetX;
  double? aimTargetY;
  bool isAiming = false;
  double _playerLockoutTimer = 0.0;

  // AI State Machine Variables
  double _aiReactionTimer = 0.0;
  double _aiTargetX = 0.0;
  double _aiTargetY = -0.85;

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
    isAiming = false;
    aimTargetX = null;
    aimTargetY = null;
    _playerLockoutTimer = 0.0;
    _aiReactionTimer = 0.0;
    playerAnimState = CharacterAnimState.idle;
    aiAnimState = CharacterAnimState.idle;
    _snapBallToServerHand();
    ballVx = 0.0;
    ballVy = 0.0;
    ballVz = 0.0;
    matchStatus =
        isPlayerServing ? 'YOUR SERVE (DRAG TO AIM)' : 'AI SERVING...';
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

  void updateAim(Offset dragNormalized) {
    if (isGameOver) return;
    isAiming = true;
    aimTargetX = (dragNormalized.dx * 0.95).clamp(-0.95, 0.95);
    aimTargetY = (-0.60 + dragNormalized.dy * 0.35).clamp(-0.90, -0.30);
    _notifyState();
  }

  void triggerDragAttack(Offset releaseNormalized, String shotType) {
    if (isGameOver) return;
    isAiming = false;

    double targetX =
        aimTargetX ?? (releaseNormalized.dx * 0.85).clamp(-0.90, 0.90);
    double targetY =
        aimTargetY ?? (-0.60 + releaseNormalized.dy * 0.30).clamp(-0.85, -0.35);

    aimTargetX = null;
    aimTargetY = null;

    if (phase == RallyPhase.readyToServe && isPlayerServing) {
      _executePlayerServe(targetX, targetY);
      return;
    }

    double dist = sqrt(pow(ballX - playerX, 2) + pow(ballY - playerY, 2));

    // Tighter hit proximity (Reduced from 0.70 to 0.35)
    if (dist <= 0.35) {
      _executePlayerHit(shotType, targetX, targetY);
    } else {
      timingFeedback = 'WHIFF!';
      playerAnimState = CharacterAnimState.smash;
      playerAnimTimer = 0.4;
      _playerLockoutTimer = 0.4;
      _clearTimingFeedback();
      _notifyState();
    }
  }

  void cancelAim() {
    isAiming = false;
    aimTargetX = null;
    aimTargetY = null;
    _notifyState();
  }

  void _executePlayerServe(double targetX, double targetY) {
    phase = RallyPhase.inFlight;
    _bounceCount = 0;
    ballX = playerX;
    ballY = playerY;
    ballHeight = 0.45;

    double airTime = 1.35;
    ballVx = (targetX - playerX) / airTime;
    ballVy = (targetY - playerY) / airTime;
    ballVz = 0.5 * gravity * airTime;

    playerAnimState = CharacterAnimState.serving;
    playerAnimTimer = 0.35;
    matchStatus = 'SERVE IN PLAY';
    timingFeedback = 'AIMED SERVE!';

    _aiReactionTimer = (0.50 - (aiDupr * 0.05)).clamp(0.15, 0.4);

    AudioService.playShotSfx('DRIVE');
    _clearTimingFeedback();
  }

  void _executePlayerHit(String shotType, double targetX, double targetY) {
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

    double airTime = 1.30;
    if (shotType == 'ULTIMATE' || isUltimateActive) {
      isUltimateActive = true;
      airTime = 0.85;
      playerAnimState = CharacterAnimState.smash;
      timingFeedback = 'STREET OVERDRIVE!';
      AudioService.playShotSfx('SMASH');
    } else {
      switch (shotType) {
        case 'SMASH':
          airTime = 1.00;
          playerAnimState = CharacterAnimState.smash;
          timingFeedback = 'POWER SLAM!';
          break;
        case 'ROLL':
        case 'SLICE':
          airTime = 1.45;
          playerAnimState = CharacterAnimState.slice;
          timingFeedback = 'SPIN DROP!';
          break;
        case 'LOB':
          airTime = 1.55;
          playerAnimState = CharacterAnimState.lob;
          timingFeedback = 'HIGH LOB!';
          break;
        case 'DRIVE':
        default:
          airTime = 1.25;
          playerAnimState = CharacterAnimState.drive;
          timingFeedback = 'TARGET DRIVE!';
          break;
      }
      AudioService.playShotSfx(shotType);
    }

    playerAnimTimer = 0.35;
    ballVx = (targetX - ballX) / airTime;
    ballVy = (targetY - ballY) / airTime;
    ballVz = 0.5 * gravity * airTime;
    matchStatus = 'RALLY IN PROGRESS';

    _aiReactionTimer = (0.45 - (aiDupr * 0.05)).clamp(0.1, 0.4);

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

    if (_playerLockoutTimer > 0) {
      _playerLockoutTimer -= dt;
    } else if (playerInputDir != Offset.zero) {
      double moveSpeed = 1.4 * characterStyle.speedMultiplier;
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

    if (phase == RallyPhase.activeRally && orbX == null) {
      _orbSpawnTimer += dt;
      if (_orbSpawnTimer > 4.0) {
        _orbSpawnTimer = 0.0;
        orbX = (Random().nextDouble() - 0.5) * 1.0;
        orbY = -0.10 + Random().nextDouble() * 0.20;
        orbType = OrbType.values[Random().nextInt(OrbType.values.length)];
      }
    }

    if (phase == RallyPhase.readyToServe && !isPlayerServing) {
      _aiServeTimer += dt;
      if (_aiServeTimer > 1.0) {
        _aiServeTimer = 0.0;
        _executeAiServe();
      }
    }

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
        timingFeedback = 'SPEED DEMON ORB!';
        break;
      case OrbType.shrinkRay:
        _aiShrinkTimer = 5.0;
        timingFeedback = 'AI PADDLE SHRUNK!';
        break;
      case OrbType.doublePoints:
        isDoublePointsActive = true;
        timingFeedback = 'DOUBLE POINTS RALLY!';
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

    double targetX = (Random().nextDouble() - 0.5) * 1.5;
    double targetY = 0.65 + Random().nextDouble() * 0.15;
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

    if (_aiReactionTimer > 0) {
      _aiReactionTimer -= dt;
    } else {
      if (ballVy > 0) {
        _aiTargetX = 0.0;
        _aiTargetY = (opponentY > -0.45) ? -0.35 : -0.85;
      } else {
        double variance = max(0, (5.0 - aiDupr)) * 0.08;
        _aiTargetX = ballX + (Random().nextDouble() - 0.5) * variance;

        if (ballHeight > 0.60 || ballVz > 0.8) {
          _aiTargetY = -0.85;
        } else if (ballY > -0.35) {
          _aiTargetY = -0.35;
        } else {
          _aiTargetY = -0.65;
        }
      }
    }

    if (opponentX < _aiTargetX - 0.04) {
      opponentX = (opponentX + aiSpeed * dt).clamp(-0.92, 0.92);
    } else if (opponentX > _aiTargetX + 0.04) {
      opponentX = (opponentX - aiSpeed * dt).clamp(-0.92, 0.92);
    }

    if (opponentY < _aiTargetY - 0.03) {
      opponentY = (opponentY + aiSpeed * 0.85 * dt).clamp(-0.92, -0.30);
    } else if (opponentY > _aiTargetY + 0.03) {
      opponentY = (opponentY - aiSpeed * 0.85 * dt).clamp(-0.92, -0.30);
    }

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

    // Scaled down AI reach to match the newly tightened player challenge mechanics
    if (ballVy < 0 && ballY <= opponentY + 0.20 && ballY >= opponentY - 0.20) {
      double reach = 0.40 + (aiDupr / 5.0) * 0.10;
      if (_aiShrinkTimer > 0) reach *= 0.50;

      if ((ballX - opponentX).abs() <= reach) {
        if (opponentY > -0.32 && ballHeight > 0.15) {
          matchStatus = 'AI KITCHEN FAULT! YOUR POINT';
          AudioService.playFaultSfx();
          _awardPointToPlayer();
          return;
        }

        _bounceCount = 0;
        phase = RallyPhase.activeRally;
        isUltimateActive = false;

        // Inject randomness into AI Targeting
        double targetX = (Random().nextDouble() - 0.5) *
            1.70; // Aim randomly across the horizontal plane
        double targetY;
        double airTime;
        int shotChoice = Random().nextInt(100);

        if (opponentY > -0.45) {
          aiAnimState = CharacterAnimState.slice;
          targetY =
              0.35 + Random().nextDouble() * 0.15; // Unpredictable short drop
          airTime = 1.45;
        } else if (ballHeight > 0.5) {
          aiAnimState = CharacterAnimState.smash;
          targetY =
              0.75 + Random().nextDouble() * 0.15; // Deep unpredictable smash
          airTime = 0.95;
        } else {
          // 25% chance the AI attempts a Lob instead of a standard Drive
          if (shotChoice < 25) {
            aiAnimState = CharacterAnimState.lob;
            targetY = 0.80 + Random().nextDouble() * 0.10;
            airTime = 1.60;
          } else {
            aiAnimState = CharacterAnimState.drive;
            targetY =
                0.60 + Random().nextDouble() * 0.30; // Random depth variation
            airTime = 1.25;
          }
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
      aimTargetX: aimTargetX,
      aimTargetY: aimTargetY,
      isAiming: isAiming,
    );
  }
}
