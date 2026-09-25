import 'package:flutter/material.dart';
import '../models/game_models.dart';

class PerspectiveCourtPainter extends CustomPainter {
  final double ballX;
  final double ballY;
  final double ballHeight;
  final double playerX;
  final double playerY;
  final double opponentX;
  final double opponentY;
  final double? orbX;
  final double? orbY;
  final OrbType? orbType;
  final bool isDoublePointsActive;
  final bool isAiShrunk;
  final String? timingFeedback;
  final Color playerColor;
  final bool isUltimateActive;
  final CharacterAnimState playerAnimState;
  final CharacterAnimState aiAnimState;
  final int playerFrame;
  final int aiFrame;

  PerspectiveCourtPainter({
    required this.ballX,
    required this.ballY,
    required this.ballHeight,
    required this.playerX,
    required this.playerY,
    required this.opponentX,
    required this.opponentY,
    this.orbX,
    this.orbY,
    this.orbType,
    required this.isDoublePointsActive,
    required this.isAiShrunk,
    this.timingFeedback,
    required this.playerColor,
    required this.isUltimateActive,
    required this.playerAnimState,
    required this.aiAnimState,
    required this.playerFrame,
    required this.aiFrame,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Perspective Court Points
    final Offset netLeft = Offset(width * 0.15, height * 0.45);
    final Offset netRight = Offset(width * 0.85, height * 0.45);
    final Offset farLeft = Offset(width * 0.28, height * 0.12);
    final Offset farRight = Offset(width * 0.72, height * 0.12);
    final Offset nearLeft = Offset(width * 0.05, height * 0.88);
    final Offset nearRight = Offset(width * 0.95, height * 0.88);

    // Court Floor
    final Path courtPath = Path()
      ..moveTo(farLeft.dx, farLeft.dy)
      ..lineTo(farRight.dx, farRight.dy)
      ..lineTo(nearRight.dx, nearRight.dy)
      ..lineTo(nearLeft.dx, nearLeft.dy)
      ..close();

    final Paint courtPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawPath(courtPath, courtPaint);

    // Court Outer Border
    final Paint linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(courtPath, linePaint);

    // Net
    final Paint netPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 4.0;
    canvas.drawLine(netLeft, netRight, netPaint);

    // Kitchen Area
    final double kitchenNearY = height * 0.58;
    final double kitchenFarY = height * 0.32;

    final Offset kitchenNearL = Offset(width * 0.11, kitchenNearY);
    final Offset kitchenNearR = Offset(width * 0.89, kitchenNearY);
    final Offset kitchenFarL = Offset(width * 0.22, kitchenFarY);
    final Offset kitchenFarR = Offset(width * 0.78, kitchenFarY);

    final Paint kitchenPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final Path kitchenPath = Path()
      ..moveTo(kitchenFarL.dx, kitchenFarL.dy)
      ..lineTo(kitchenFarR.dx, kitchenFarR.dy)
      ..lineTo(kitchenNearR.dx, kitchenNearR.dy)
      ..lineTo(kitchenNearL.dx, kitchenNearL.dy)
      ..close();
    canvas.drawPath(kitchenPath, kitchenPaint);

    canvas.drawLine(kitchenFarL, kitchenFarR, linePaint);
    canvas.drawLine(kitchenNearL, kitchenNearR, linePaint);

    // Center Baseline Splits
    canvas.drawLine(
      Offset((nearLeft.dx + nearRight.dx) / 2, kitchenNearY),
      Offset((nearLeft.dx + nearRight.dx) / 2, nearLeft.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset((farLeft.dx + farRight.dx) / 2, kitchenFarY),
      Offset((farLeft.dx + farRight.dx) / 2, farLeft.dy),
      linePaint,
    );

    // Power Orbs
    if (orbX != null && orbY != null && orbType != null) {
      final Offset orbPos = perspectiveTransform(orbX!, orbY!, width, height);
      Color orbColor = const Color(0xFF38BDF8);
      if (orbType == OrbType.shrinkRay || orbType == OrbType.shrinkOpponent) {
        orbColor = const Color(0xFFFA855F);
      } else if (orbType == OrbType.doublePoints) {
        orbColor = const Color(0xFFEAB308);
      }

      canvas.drawCircle(
        orbPos,
        18,
        Paint()
          ..color = orbColor.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(orbPos, 12, Paint()..color = orbColor);
      canvas.drawCircle(orbPos, 6, Paint()..color = Colors.white);
    }

    // AI Opponent
    final Offset oppPos =
        perspectiveTransform(opponentX, opponentY, width, height);
    _drawAnimatedChibi(
      canvas: canvas,
      position: oppPos,
      color: Colors.redAccent,
      isPlayer: false,
      scale: isAiShrunk ? 0.6 : 0.9,
      animState: aiAnimState,
      frame: aiFrame,
    );

    // Player
    final Offset playerPos =
        perspectiveTransform(playerX, playerY, width, height);
    _drawAnimatedChibi(
      canvas: canvas,
      position: playerPos,
      color: playerColor,
      isPlayer: true,
      scale: 1.2,
      isGlowing: isUltimateActive,
      animState: playerAnimState,
      frame: playerFrame,
    );

    // Ball & Shadow
    final Offset ballPos = perspectiveTransform(ballX, ballY, width, height);
    final double shadowOffsetY = 15.0 * (1.0 - ballY.abs());

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(ballPos.dx, ballPos.dy + shadowOffsetY),
        width: 16 * (1.0 - ballHeight * 0.3),
        height: 8 * (1.0 - ballHeight * 0.3),
      ),
      Paint()..color = Colors.black45,
    );

    final Offset floatingBallPos = Offset(
      ballPos.dx,
      ballPos.dy - (ballHeight * 60.0),
    );
    canvas.drawCircle(
      floatingBallPos,
      10,
      Paint()..color = const Color(0xFFCCFF00),
    );
    canvas.drawCircle(
      floatingBallPos,
      10,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Hit Timing Feedback Banner
    if (timingFeedback != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: timingFeedback,
          style: const TextStyle(
            color: Color(0xFFFACC15),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black, blurRadius: 6)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          playerPos.dx - (textPainter.width / 2),
          playerPos.dy - 90,
        ),
      );
    }
  }

  Offset perspectiveTransform(
      double normX, double normY, double width, double height) {
    final double tY = (normY + 1.0) / 2.0;
    final double screenY = height * (0.15 + (tY * 0.72));

    final double rowWidth = width * (0.44 + (tY * 0.50));
    final double centerX = width / 2;
    final double screenX = centerX + (normX * (rowWidth / 2));

    return Offset(screenX, screenY);
  }

  void _drawAnimatedChibi({
    required Canvas canvas,
    required Offset position,
    required Color color,
    required bool isPlayer,
    required double scale,
    bool isGlowing = false,
    required CharacterAnimState animState,
    required int frame,
  }) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(scale);

    final Paint bodyPaint = Paint()..color = color;
    final Paint skinPaint = Paint()..color = const Color(0xFFFFDBA7);

    if (isGlowing) {
      canvas.drawCircle(
        Offset.zero,
        35,
        Paint()
          ..color = Colors.amberAccent.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    double legOffsetLeft = (frame % 2 == 0) ? -3.0 : 3.0;
    double legOffsetRight = (frame % 2 == 0) ? 3.0 : -3.0;

    if (animState == CharacterAnimState.idle) {
      legOffsetLeft = 0;
      legOffsetRight = 0;
    }

    // Legs
    canvas.drawRRect(
      RRect.fromLTRBR(
          -8, -12 + legOffsetLeft, -3, -2, const Radius.circular(2)),
      skinPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(3, -12 + legOffsetRight, 8, -2, const Radius.circular(2)),
      skinPaint,
    );

    // Torso
    canvas.drawRRect(
      RRect.fromLTRBR(-12, -32, 12, -12, const Radius.circular(6)),
      bodyPaint,
    );

    // Head
    canvas.drawCircle(const Offset(0, -42), 16, skinPaint);

    // Eyes
    final Paint eyePaint = Paint()..color = Colors.black;
    if (isPlayer) {
      canvas.drawCircle(const Offset(-5, -44), 2.5, eyePaint);
      canvas.drawCircle(const Offset(5, -44), 2.5, eyePaint);
    } else {
      canvas.drawCircle(const Offset(-5, -40), 2.5, eyePaint);
      canvas.drawCircle(const Offset(5, -40), 2.5, eyePaint);
    }

    Offset paddleHand =
        isPlayer ? const Offset(18, -26) : const Offset(-18, -26);
    double paddleAngle = 0.0;

    switch (animState) {
      case CharacterAnimState.smash:
      case CharacterAnimState.hit:
        paddleHand = isPlayer ? const Offset(10, -50) : const Offset(-10, -50);
        paddleAngle = isPlayer ? -0.4 : 0.4;
        break;
      case CharacterAnimState.slice:
      case CharacterAnimState.run:
        paddleHand = isPlayer ? const Offset(20, -18) : const Offset(-20, -18);
        paddleAngle = isPlayer ? 0.8 : -0.8;
        break;
      case CharacterAnimState.lob:
        paddleHand = isPlayer ? const Offset(16, -38) : const Offset(-16, -38);
        paddleAngle = isPlayer ? -0.9 : 0.9;
        break;
      case CharacterAnimState.serving:
      case CharacterAnimState.serve:
        paddleHand = isPlayer ? const Offset(18, -22) : const Offset(-18, -22);
        paddleAngle = isPlayer ? 0.5 : -0.5;
        break;
      case CharacterAnimState.drive:
        paddleHand = isPlayer ? const Offset(18, -32) : const Offset(-18, -32);
        paddleAngle = isPlayer ? -0.2 : 0.2;
        break;
      case CharacterAnimState.idle:
      default:
        paddleHand = isPlayer ? const Offset(18, -26) : const Offset(-18, -26);
        paddleAngle = 0.0;
        break;
    }

    // Draw Paddle
    canvas.save();
    canvas.translate(paddleHand.dx, paddleHand.dy);
    canvas.rotate(paddleAngle);

    final Paint paddleHeadPaint = Paint()..color = const Color(0xFF22C55E);
    final Paint paddleHandlePaint = Paint()..color = const Color(0xFF78350F);

    canvas.drawRect(const Rect.fromLTWH(-2, 0, 4, 10), paddleHandlePaint);
    canvas.drawRRect(
      RRect.fromLTRBR(-8, -18, 8, 0, const Radius.circular(4)),
      paddleHeadPaint,
    );

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PerspectiveCourtPainter oldDelegate) => true;
}
