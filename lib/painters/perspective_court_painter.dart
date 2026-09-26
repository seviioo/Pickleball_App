import 'package:flutter/material.dart';
import '../game/pickleball_game.dart';
import 'dart:math';

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
  final double? aimTargetX;
  final double? aimTargetY;
  final bool isAiming;

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
    this.isUltimateActive = false,
    required this.playerAnimState,
    required this.aiAnimState,
    required this.playerFrame,
    required this.aiFrame,
    this.aimTargetX,
    this.aimTargetY,
    this.isAiming = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final darkAsphaltPaint = Paint()
      ..color = const Color(0xFF09090B)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, darkAsphaltPaint);

    const streetGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF18181B),
        Color(0xFF09090B),
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = streetGradient.createShader(Offset.zero & size),
    );

    final double topWidth = size.width * 0.40;
    final double bottomWidth = size.width * 0.84;
    final double topY = size.height * 0.16;
    final double bottomY = size.height * 0.88;
    final double centerX = size.width / 2;

    Offset perspectiveTransform(double normX, double normY) {
      double progressY = (normY + 1.0) / 2.0;
      double currentY = topY + progressY * (bottomY - topY);
      double currentWidth = topWidth + progressY * (bottomWidth - topWidth);
      double currentX = centerX + (normX * currentWidth / 2);
      return Offset(currentX, currentY);
    }

    // Court Surface
    final Path courtPath = Path()
      ..moveTo(perspectiveTransform(-1.0, -1.0).dx,
          perspectiveTransform(-1.0, -1.0).dy)
      ..lineTo(perspectiveTransform(1.0, -1.0).dx,
          perspectiveTransform(1.0, -1.0).dy)
      ..lineTo(
          perspectiveTransform(1.0, 1.0).dx, perspectiveTransform(1.0, 1.0).dy)
      ..lineTo(perspectiveTransform(-1.0, 1.0).dx,
          perspectiveTransform(-1.0, 1.0).dy)
      ..close();

    canvas.drawPath(
      courtPath,
      Paint()
        ..color = const Color(0xFF27272A)
        ..style = PaintingStyle.fill,
    );

    // Kitchen (NVZ) Surface
    final Path kitchenPath = Path()
      ..moveTo(perspectiveTransform(-1.0, -0.32).dx,
          perspectiveTransform(-1.0, -0.32).dy)
      ..lineTo(perspectiveTransform(1.0, -0.32).dx,
          perspectiveTransform(1.0, -0.32).dy)
      ..lineTo(perspectiveTransform(1.0, 0.32).dx,
          perspectiveTransform(1.0, 0.32).dy)
      ..lineTo(perspectiveTransform(-1.0, 0.32).dx,
          perspectiveTransform(-1.0, 0.32).dy)
      ..close();

    canvas.drawPath(
      kitchenPath,
      Paint()
        ..color = const Color(0xFF991B1B)
        ..style = PaintingStyle.fill,
    );

    // Court Lines
    final Paint linePaint = Paint()
      ..color = const Color(0xFFF4F4F5)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(courtPath, linePaint);

    Offset netLeft = perspectiveTransform(-1.0, 0.0);
    Offset netRight = perspectiveTransform(1.0, 0.0);

    canvas.drawLine(netLeft, netRight, linePaint);
    canvas.drawLine(perspectiveTransform(-1.0, -0.32),
        perspectiveTransform(1.0, -0.32), linePaint);
    canvas.drawLine(perspectiveTransform(-1.0, 0.32),
        perspectiveTransform(1.0, 0.32), linePaint);
    canvas.drawLine(perspectiveTransform(0.0, -1.0),
        perspectiveTransform(0.0, -0.32), linePaint);
    canvas.drawLine(perspectiveTransform(0.0, 0.32),
        perspectiveTransform(0.0, 1.0), linePaint);

    // Dynamic Aim Direction & Trajectory Preview
    if (isAiming && aimTargetX != null && aimTargetY != null) {
      Offset playerPos = perspectiveTransform(playerX, playerY);
      Offset targetPos = perspectiveTransform(aimTargetX!, aimTargetY!);

      final Paint trajectoryPaint = Paint()
        ..color = const Color(0xFFFACC15)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      double dx = targetPos.dx - playerPos.dx;
      double dy = targetPos.dy - playerPos.dy;
      int segments = 12;

      for (int i = 0; i < segments; i += 2) {
        double startRatio = i / segments;
        double endRatio = (i + 1) / segments;
        canvas.drawLine(
          Offset(
              playerPos.dx + dx * startRatio, playerPos.dy + dy * startRatio),
          Offset(playerPos.dx + dx * endRatio, playerPos.dy + dy * endRatio),
          trajectoryPaint,
        );
      }

      canvas.drawCircle(
        targetPos,
        14,
        Paint()
          ..color = const Color(0xFFFACC15).withValues(alpha: 0.35)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        targetPos,
        14,
        Paint()
          ..color = const Color(0xFFFACC15)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(targetPos, 4, Paint()..color = const Color(0xFFEF4444));
    }

    // Net Mesh
    final double netHeightPx = size.height * 0.075;
    final Offset netTopLeft = Offset(netLeft.dx - 3, netLeft.dy - netHeightPx);
    final Offset netTopRight =
        Offset(netRight.dx + 3, netRight.dy - netHeightPx);

    final Path netMeshPath = Path()
      ..moveTo(netLeft.dx, netLeft.dy)
      ..lineTo(netRight.dx, netRight.dy)
      ..lineTo(netTopRight.dx, netTopRight.dy)
      ..lineTo(netTopLeft.dx, netTopLeft.dy)
      ..close();

    canvas.drawPath(
        netMeshPath, Paint()..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawLine(
      netTopLeft,
      netTopRight,
      Paint()
        ..color = const Color(0xFFFACC15)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round,
    );

    final Paint postPaint = Paint()
      ..color = const Color(0xFF71717A)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(netLeft,
        Offset(netLeft.dx - 2, netLeft.dy - netHeightPx * 1.05), postPaint);
    canvas.drawLine(netRight,
        Offset(netRight.dx + 2, netRight.dy - netHeightPx * 1.05), postPaint);

    // Power Orbs
    if (orbX != null && orbY != null && orbType != null) {
      Offset orbPos = perspectiveTransform(orbX!, orbY!);
      Color orbColor = const Color(0xFFF97316);
      if (orbType == OrbType.shrinkRay) orbColor = const Color(0xFFA855F7);
      if (orbType == OrbType.doublePoints) orbColor = const Color(0xFFEAB308);

      canvas.drawCircle(
        orbPos,
        18,
        Paint()
          ..color = orbColor.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(orbPos, 12, Paint()..color = orbColor);
      canvas.drawCircle(orbPos, 6, Paint()..color = Colors.white);
    }

    // AI Chibi Render
    Offset oppPos = perspectiveTransform(opponentX, opponentY);
    _drawAnimatedChibi(
      canvas,
      position: oppPos,
      scale: 0.72,
      shirtColor: const Color(0xFF1E3A8A),
      isPlayer: false,
      isShrunk: isAiShrunk,
      animState: aiAnimState,
      frame: aiFrame,
    );

    // Player Chibi Render
    Offset playerPos = perspectiveTransform(playerX, playerY);
    _drawAnimatedChibi(
      canvas,
      position: playerPos,
      scale: 1.1,
      shirtColor: playerColor,
      isPlayer: true,
      isGlowing: isUltimateActive,
      animState: playerAnimState,
      frame: playerFrame,
    );

    // Pseudo-3D Depth Scaling Calculation for the Ball
    Offset ballCourtPos = perspectiveTransform(ballX, ballY);
    double depthScale = 0.45 + ((ballY + 1.0) / 2.0) * 0.55;
    depthScale = depthScale.clamp(0.3, 1.2);

    double renderBallY = ballCourtPos.dy - (ballHeight * 60.0 * depthScale);
    final Offset ballCenter = Offset(ballCourtPos.dx, renderBallY);

    double shadowWidth =
        (20.0 - ballHeight * 6.0).clamp(6.0, 20.0) * depthScale;
    double shadowHeight =
        (10.0 - ballHeight * 3.0).clamp(3.0, 10.0) * depthScale;

    canvas.drawOval(
      Rect.fromCenter(
          center: ballCourtPos, width: shadowWidth, height: shadowHeight),
      Paint()..color = Colors.black54,
    );

    Color ballColor = isDoublePointsActive
        ? const Color(0xFFEAB308)
        : const Color(0xFFFACC15);
    canvas.drawCircle(ballCenter, 9.0 * depthScale, Paint()..color = ballColor);

    final Paint holePaint = Paint()..color = Colors.black45;
    canvas.drawCircle(
        Offset(ballCenter.dx - 2 * depthScale, ballCenter.dy - 2 * depthScale),
        1.0 * depthScale,
        holePaint);
    canvas.drawCircle(
        Offset(ballCenter.dx + 2 * depthScale, ballCenter.dy - 1 * depthScale),
        1.0 * depthScale,
        holePaint);
    canvas.drawCircle(Offset(ballCenter.dx, ballCenter.dy + 2 * depthScale),
        1.0 * depthScale, holePaint);

    if (timingFeedback != null && timingFeedback!.isNotEmpty) {
      Color feedbackColor = timingFeedback == 'WHIFF!'
          ? const Color(0xFFDC2626)
          : const Color(0xFFFACC15);
      final textSpan = TextSpan(
        text: timingFeedback,
        style: TextStyle(
          color: feedbackColor,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          shadows: const [
            Shadow(
                offset: Offset(1.5, 1.5), color: Colors.black, blurRadius: 4),
          ],
        ),
      );
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr)
            ..layout();
      textPainter.paint(canvas,
          Offset(playerPos.dx - textPainter.width / 2, playerPos.dy - 85));
    }
  }

  void _drawAnimatedChibi(
    Canvas canvas, {
    required Offset position,
    required double scale,
    required Color shirtColor,
    required bool isPlayer,
    bool isGlowing = false,
    bool isShrunk = false,
    required CharacterAnimState animState,
    required int frame,
  }) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(scale);

    final Paint skinPaint = Paint()..color = const Color(0xFFFDBA74);

    double legOffsetLeft = (frame % 2 == 0) ? -3.0 : 3.0;
    double legOffsetRight = (frame % 2 == 0) ? 3.0 : -3.0;
    if (animState == CharacterAnimState.idle) {
      legOffsetLeft = 0;
      legOffsetRight = 0;
    }

    canvas.drawRRect(
      RRect.fromLTRBR(
          -8, -12 + legOffsetLeft, -3, -2, const Radius.circular(2)),
      skinPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(3, -12 + legOffsetRight, 8, -2, const Radius.circular(2)),
      skinPaint,
    );

    canvas.drawRRect(
      RRect.fromLTRBR(-10, -22, 10, -10, const Radius.circular(4)),
      Paint()..color = const Color(0xFF18181B),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(-11, -38, 11, -20, const Radius.circular(6)),
      Paint()..color = shirtColor,
    );

    canvas.drawCircle(const Offset(0, -50), 16, skinPaint);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, -54), radius: 17),
      3.14,
      3.14,
      true,
      Paint()..color = const Color(0xFF27272A),
    );

    Offset paddleHand =
        isPlayer ? const Offset(14, -28) : const Offset(-14, -28);
    double paddleAngle = 0.0;
    double paddleScale = isShrunk ? 0.5 : 1.0;

    switch (animState) {
      case CharacterAnimState.smash:
        paddleHand = isPlayer ? const Offset(10, -68) : const Offset(-10, -68);
        paddleAngle = isPlayer ? -0.4 : 0.4;
        break;
      case CharacterAnimState.slice:
        paddleHand = isPlayer ? const Offset(20, -18) : const Offset(-20, -18);
        paddleAngle = isPlayer ? 0.8 : -0.8;
        break;
      case CharacterAnimState.lob:
        paddleHand = isPlayer ? const Offset(16, -38) : const Offset(-16, -38);
        paddleAngle = isPlayer ? -0.9 : 0.9;
        break;
      case CharacterAnimState.serving:
        paddleHand = isPlayer ? const Offset(18, -22) : const Offset(-18, -22);
        paddleAngle = isPlayer ? 0.5 : -0.5;
        break;
      case CharacterAnimState.drive:
        paddleHand = isPlayer ? const Offset(18, -32) : const Offset(-18, -32);
        paddleAngle = isPlayer ? -0.2 : 0.2;
        break;
      default:
        break;
    }

    canvas.save();
    canvas.translate(paddleHand.dx, paddleHand.dy);
    canvas.rotate(paddleAngle);
    canvas.scale(paddleScale);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 14, height: 18),
        const Radius.circular(4),
      ),
      Paint()
        ..color = isGlowing ? const Color(0xFFF97316) : const Color(0xFFEF4444),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PerspectiveCourtPainter oldDelegate) => true;
}
