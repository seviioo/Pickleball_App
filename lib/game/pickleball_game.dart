import 'dart:async';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/audio_service.dart';

enum RallyPhase {
  readyToServe,
  ballInAir,
  pointFinished,
}

class PickleballGame extends FlameGame {
  final String userName;
  final PaddleData paddle;
  final CharacterStyleData characterStyle;
  final int targetScore;
  final double aiDupr;

  final Function({
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
    required int smashesLanded,
    required int longestRally,
    required int kitchenFaults,
  }) onStateUpdate;

  PickleballGame({
    required this.userName,
    required this.paddle,
    required this.characterStyle,
    required this.targetScore,
    required this.aiDupr,
    required this.onStateUpdate,
  });

  int playerScore = 0;
  int opponentScore = 0;
  bool isPlayerServing = true;
  String matchStatus = 'STREET SERVE READY';
  bool isGameOver = false;

  double ballX = 0.0;
  double ballY = 0.85;
  double ballHeight = 0.4;
  double ballVx = 0.0;
  double ballVy = 0.0;
  double ballVz = 0.0;

  double playerX = 0.0;
  double playerY = 0.85;
  double opponentX = 0.0;
  double opponentY = -0.85;

  Offset playerInputDir = Offset.zero;
  RallyPhase phase = RallyPhase.readyToServe;

  double ultimateGauge = 0.0;
  bool isUltimateActive = false;

  double? orbX;
  double? orbY;
  OrbType? orbType;
  bool isDoublePointsActive = false;
  bool isAiShrunk = false;
  double _aiShrunkTimer = 0.0;

  String? timingFeedback;

  CharacterAnimState playerAnimState = CharacterAnimState.idle;
  CharacterAnimState aiAnimState = CharacterAnimState.idle;
  int playerFrame = 0;
  int aiFrame = 0;
  double _playerAnimTimer = 0.0;
  double _aiAnimTimer = 0.0;

  // Match Breakdown Tracking
  int smashesLanded = 0;
  int currentRallyCount = 0;
  int longestRally = 0;
  int kitchenFaults = 0;
  bool _ballBounced = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    resetPositions(isPlayerServing: true);
  }

  void updatePlayerMovement(Offset direction) {
    playerInputDir = direction;
  }

  void resetPositions({required bool isPlayerServing}) {
    this.isPlayerServing = isPlayerServing;
    phase = RallyPhase.readyToServe;
    currentRallyCount = 0;
    _ballBounced = false;

    playerX = 0.0;
    playerY = 0.85;
    opponentX = 0.0;
    opponentY = -0.85;

    _snapBallToServerHand();

    matchStatus = isPlayerServing ? 'YOUR SERVE' : 'RIVAL SERVING...';
    _notifyState();

    if (!isPlayerServing) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (phase == RallyPhase.readyToServe && !isGameOver) {
          _aiServe();
        }
      });
    }
  }

  void _snapBallToServerHand() {
    if (isPlayerServing) {
      ballX = playerX + 0.05;
      ballY = playerY - 0.05;
      ballHeight = 0.35;
    } else {
      ballX = opponentX - 0.05;
      ballY = opponentY + 0.05;
      ballHeight = 0.35;
    }
    ballVx = 0.0;
    ballVy = 0.0;
    ballVz = 0.0;
  }

  void triggerAttack(String type) {
    if (isGameOver) return;

    if (phase == RallyPhase.readyToServe &&
        isPlayerServing &&
        type == 'SERVE') {
      phase = RallyPhase.ballInAir;
      ballVx = (math.Random().nextDouble() - 0.5) * 0.4;
      ballVy = -1.3;
      ballVz = 1.1;
      currentRallyCount = 1;
      if (currentRallyCount > longestRally) longestRally = currentRallyCount;
      matchStatus = 'RALLY IN PROGRESS';
      AudioService.playHitSound('DRIVE');
      _notifyState();
      return;
    }

    if (phase == RallyPhase.ballInAir) {
      final dist = math
          .sqrt(math.pow(ballX - playerX, 2) + math.pow(ballY - playerY, 2));
      if (dist < 0.35 && ballY > 0.3) {
        playerAnimState = CharacterAnimState.hit;
        _playerAnimTimer = 0.25;

        // Kitchen Fault Check
        if (playerY < 0.55 && !_ballBounced) {
          kitchenFaults++;
          timingFeedback = 'KITCHEN FAULT!';
          AudioService.playHitSound('FAULT');
          _awardPoint(isPlayerWin: false);
          return;
        }

        currentRallyCount++;
        if (currentRallyCount > longestRally) {
          longestRally = currentRallyCount;
        }
        _ballBounced = false;

        double baseVy = -1.4;
        double baseVz = 1.0;

        switch (type) {
          case 'SMASH':
            baseVy = -2.2;
            baseVz = 0.6;
            smashesLanded++;
            timingFeedback = 'POWER SMASH!';
            break;
          case 'LOB':
            baseVy = -1.1;
            baseVz = 1.8;
            timingFeedback = 'HIGH LOB';
            break;
          case 'ROLL':
            baseVy = -1.3;
            baseVz = 0.8;
            timingFeedback = 'SLICE SPIN';
            break;
          case 'DRIVE':
          default:
            baseVy = -1.6;
            baseVz = 1.1;
            timingFeedback = 'CLEAN DRIVE';
            break;
        }

        ballVx = (math.Random().nextDouble() - 0.5) * 0.6;
        ballVy = baseVy;
        ballVz = baseVz;

        AudioService.playHitSound(type);
        _clearTimingFeedback();
        _notifyState();
      }
    }
  }

  void _aiServe() {
    if (isGameOver || phase != RallyPhase.readyToServe) return;
    phase = RallyPhase.ballInAir;
    ballVx = (math.Random().nextDouble() - 0.5) * 0.3;
    ballVy = 1.2;
    ballVz = 1.0;
    currentRallyCount = 1;
    if (currentRallyCount > longestRally) longestRally = currentRallyCount;
    matchStatus = 'RALLY IN PROGRESS';
    AudioService.playHitSound('DRIVE');
    _notifyState();
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

    if (_aiShrunkTimer > 0) _aiShrunkTimer -= dt;
    isAiShrunk = _aiShrunkTimer > 0;

    // Movement Logic
    double moveSpeed = 1.4 * characterStyle.speedMultiplier;
    if (playerInputDir != Offset.zero) {
      playerX =
          (playerX + playerInputDir.dx * moveSpeed * dt).clamp(-0.92, 0.92);
      playerY =
          (playerY + playerInputDir.dy * moveSpeed * dt).clamp(0.20, 0.92);

      if (_playerAnimTimer <= 0) {
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
    } else if (_playerAnimTimer <= 0) {
      playerAnimState = CharacterAnimState.idle;
    }

    if (_playerAnimTimer > 0) {
      _playerAnimTimer -= dt;
    }

    // AI Tracking
    if (phase == RallyPhase.ballInAir && ballVy < 0) {
      double aiSpeed = 0.8 + (aiDupr * 0.1);
      double targetX = ballX.clamp(-0.85, 0.85);
      if (opponentX < targetX) opponentX += aiSpeed * dt;
      if (opponentX > targetX) opponentX -= aiSpeed * dt;

      // AI Return Hit
      if (ballY < -0.3 &&
          math.sqrt(math.pow(ballX - opponentX, 2) +
                  math.pow(ballY - opponentY, 2)) <
              0.3) {
        ballVx = (math.Random().nextDouble() - 0.5) * 0.5;
        ballVy = 1.4 + (aiDupr * 0.08);
        ballVz = 1.0;
        aiAnimState = CharacterAnimState.hit;
        _aiAnimTimer = 0.25;

        currentRallyCount++;
        if (currentRallyCount > longestRally) {
          longestRally = currentRallyCount;
        }
        _ballBounced = false;

        AudioService.playHitSound('DRIVE');
      }
    } else {
      if (_aiAnimTimer <= 0) aiAnimState = CharacterAnimState.idle;
    }

    if (_aiAnimTimer > 0) _aiAnimTimer -= dt;

    // Ball Physics
    if (phase == RallyPhase.ballInAir) {
      ballX += ballVx * dt;
      ballY += ballVy * dt;
      ballHeight += ballVz * dt;
      ballVz -= 2.5 * dt;

      if (ballHeight <= 0) {
        ballHeight = 0;
        ballVz = -ballVz * 0.55;
        _ballBounced = true;

        // Out of Bounds / Scoring
        if (ballY > 1.0) {
          _awardPoint(isPlayerWin: false);
        } else if (ballY < -1.0) {
          _awardPoint(isPlayerWin: true);
        }
      }
    }

    _notifyState();
  }

  void _awardPoint({required bool isPlayerWin}) {
    phase = RallyPhase.pointFinished;
    if (isPlayerWin) {
      playerScore += isDoublePointsActive ? 2 : 1;
      matchStatus = 'POINT FOR YOU!';
      AudioService.playHitSound('DRIVE');
    } else {
      opponentScore += 1;
      matchStatus = 'POINT FOR RIVAL!';
      AudioService.playHitSound('FAULT');
    }

    if (playerScore >= targetScore || opponentScore >= targetScore) {
      isGameOver = true;
      matchStatus = playerScore >= targetScore ? 'MATCH WON!' : 'MATCH LOST!';
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!isGameOver) {
          resetPositions(isPlayerServing: isPlayerWin);
        }
      });
    }
    _notifyState();
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
      isAiShrunk: isAiShrunk,
      timingFeedback: timingFeedback,
      playerAnimState: playerAnimState,
      aiAnimState: aiAnimState,
      playerFrame: playerFrame,
      aiFrame: aiFrame,
      smashesLanded: smashesLanded,
      longestRally: longestRally,
      kitchenFaults: kitchenFaults,
    );
  }
}
