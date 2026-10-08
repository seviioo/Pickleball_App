import 'dart:math';
import 'package:flutter/material.dart';
import '../game/pickleball_game.dart';

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
  final double ballVx;
  final double ballVy;
  final double ballVz;
  final double ballRotation;
  final double ballImpact;
  final List<BallTrailPoint> trail;
  final double animClock;
  final double playerWalkPhase;
  final double aiWalkPhase;
  final double playerMoveAmount;
  final double playerMoveX;
  final double aiMoveAmount;
  final double aiMoveX;
  final double playerActionProgress;
  final double aiActionProgress;
  final double playerReach;
  final bool ballInReach;
  final double aimX;
  final double aimY;
  final double aimScatter;
  final bool showAim;

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
    this.ballVx = 0.0,
    this.ballVy = 0.0,
    this.ballVz = 0.0,
    this.ballRotation = 0.0,
    this.ballImpact = 0.0,
    this.trail = const [],
    this.animClock = 0.0,
    this.playerWalkPhase = 0.0,
    this.aiWalkPhase = 0.0,
    this.playerMoveAmount = 0.0,
    this.playerMoveX = 0.0,
    this.aiMoveAmount = 0.0,
    this.aiMoveX = 0.0,
    this.playerActionProgress = 1.0,
    this.aiActionProgress = 1.0,
    this.playerReach = 0.0,
    this.ballInReach = false,
    this.aimX = 0.0,
    this.aimY = -0.75,
    this.aimScatter = 0.15,
    this.showAim = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool isLandscape = size.width > size.height;

    final darkAsphaltPaint = Paint()
      ..color = const Color(0xFF09090B)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, darkAsphaltPaint);

    final streetGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF18181B), Color(0xFF09090B)],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = streetGradient.createShader(Offset.zero & size),
    );

    // Calculate court scaling & proportions dynamically for orientation
    final double maxCourtWidth =
        isLandscape ? size.width * 0.60 : size.width * 0.85;
    final double maxCourtHeight =
        isLandscape ? size.height * 0.85 : size.height * 0.80;

    // Pick proportional width/height bounds
    final double courtHeight = min(maxCourtHeight, maxCourtWidth * 1.6);
    final double topWidth = courtHeight * 0.35;
    final double bottomWidth = courtHeight * 0.65;

    final double centerY = size.height * 0.50;
    final double topY = centerY - (courtHeight * 0.45);
    final double bottomY = centerY + (courtHeight * 0.45);
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

    // Net Mesh
    final double netHeightPx = courtHeight * 0.08;
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
        netMeshPath, Paint()..color = Colors.black.withOpacity(0.55));
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
          ..color = orbColor.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(orbPos, 12, Paint()..color = orbColor);
      canvas.drawCircle(orbPos, 6, Paint()..color = Colors.white);
    }

    // Player Reach Ring
    if (playerReach > 0) {
      final Offset pp = perspectiveTransform(playerX, playerY);
      final double prog = (playerY + 1.0) / 2.0;
      final double curW = topWidth + prog * (bottomWidth - topWidth);
      final Rect reachRect = Rect.fromCenter(
        center: pp,
        width: playerReach * curW,
        height: playerReach * (bottomY - topY),
      );
      final Color ringColor = const Color(0xFFFACC15);

      canvas.drawOval(
        reachRect,
        Paint()
          ..color = ringColor.withOpacity(ballInReach ? 0.16 : 0.05)
          ..style = PaintingStyle.fill,
      );
      canvas.drawOval(
        reachRect,
        Paint()
          ..color = ringColor.withOpacity(ballInReach ? 0.85 : 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ballInReach ? 2.5 : 1.5,
      );
    }

    // Aim Reticle
    if (showAim) {
      final Offset from = perspectiveTransform(playerX, playerY);
      final Offset to = perspectiveTransform(aimX, aimY);
      final double aprog = (aimY + 1.0) / 2.0;
      final double aw = topWidth + aprog * (bottomWidth - topWidth);
      final double rx = max(9.0, aimScatter * aw / 2);
      final double ry = rx * 0.45;

      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = Colors.white.withOpacity(0.16)
          ..strokeWidth = 1.5,
      );

      final Rect target =
          Rect.fromCenter(center: to, width: rx * 2, height: ry * 2);
      canvas.drawOval(
        target,
        Paint()
          ..color = const Color(0xFFEF4444).withOpacity(0.20)
          ..style = PaintingStyle.fill,
      );

      final Paint aimStroke = Paint()
        ..color = const Color(0xFFEF4444).withOpacity(0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawOval(target, aimStroke);
      canvas.drawLine(Offset(to.dx - rx * 0.5, to.dy),
          Offset(to.dx + rx * 0.5, to.dy), aimStroke);
      canvas.drawLine(Offset(to.dx, to.dy - ry * 0.5),
          Offset(to.dx, to.dy + ry * 0.5), aimStroke);
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
      walkPhase: aiWalkPhase,
      moveAmount: aiMoveAmount,
      moveX: aiMoveX,
      actionProgress: aiActionProgress,
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
      walkPhase: playerWalkPhase,
      moveAmount: playerMoveAmount,
      moveX: playerMoveX,
      actionProgress: playerActionProgress,
    );

    // Ball & Trail Rendering
    Offset project(double x, double y, double h) {
      final Offset base = perspectiveTransform(x, y);
      return Offset(base.dx, base.dy - h * 60.0);
    }

    Offset ballCourtPos = perspectiveTransform(ballX, ballY);
    final Offset ballCenter = project(ballX, ballY, ballHeight);
    Color ballColor = isDoublePointsActive
        ? const Color(0xFFEAB308)
        : const Color(0xFFFACC15);

    final double speedXY = sqrt(ballVx * ballVx + ballVy * ballVy);
    final double trailStrength = ((speedXY - 0.8) / 1.6).clamp(0.0, 1.0);
    if (trailStrength > 0 && trail.length > 1) {
      for (int i = 0; i < trail.length; i++) {
        final double t = (i + 1) / trail.length;
        final Offset tp = project(trail[i].x, trail[i].y, trail[i].h);
        canvas.drawCircle(
          tp,
          2.0 + 6.0 * t,
          Paint()..color = ballColor.withOpacity(0.30 * t * trailStrength),
        );
      }
    }

    double shadowWidth = (20.0 - ballHeight * 6.0).clamp(6.0, 20.0);
    double shadowHeight = (10.0 - ballHeight * 3.0).clamp(3.0, 10.0);
    canvas.drawOval(
      Rect.fromCenter(
          center: ballCourtPos, width: shadowWidth, height: shadowHeight),
      Paint()..color = Colors.black54,
    );

    final Offset ahead = project(ballX + ballVx * 0.03, ballY + ballVy * 0.03,
        ballHeight + ballVz * 0.03);
    final Offset dir = ahead - ballCenter;
    final double screenSpeed = dir.distance;
    final double travelAngle = screenSpeed > 0.01 ? atan2(dir.dy, dir.dx) : 0.0;
    final double stretch = 1.0 + (screenSpeed / 40.0).clamp(0.0, 0.55);
    final double impact = (ballImpact / 0.12).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(ballCenter.dx, ballCenter.dy);
    canvas.scale(1.0 + 0.35 * impact, 1.0 - 0.30 * impact);
    canvas.rotate(travelAngle);
    canvas.scale(stretch, 1.0 / sqrt(stretch));
    canvas.drawCircle(Offset.zero, 9.0, Paint()..color = ballColor);

    canvas.rotate(ballRotation - travelAngle);
    final Paint holePaint = Paint()..color = Colors.black45;
    canvas.drawCircle(const Offset(-2.5, -2.5), 1.1, holePaint);
    canvas.drawCircle(const Offset(2.5, -1.5), 1.1, holePaint);
    canvas.drawCircle(const Offset(0, 2.5), 1.1, holePaint);
    canvas.drawCircle(const Offset(-3.5, 2.0), 1.0, holePaint);
    canvas.drawCircle(const Offset(3.5, 2.5), 1.0, holePaint);
    canvas.restore();

    if (timingFeedback != null && timingFeedback!.isNotEmpty) {
      final textSpan = TextSpan(
        text: timingFeedback,
        style: const TextStyle(
          color: Color(0xFFFACC15),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          shadows: [
            Shadow(offset: Offset(1.5, 1.5), color: Colors.black, blurRadius: 4)
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

  static const Map<CharacterAnimState, List<List<double>>> _swingKeys = {
    CharacterAnimState.serving: [
      [0.00, 8.0, -14.0, -0.9],
      [0.25, 20.0, -30.0, 0.4],
      [0.60, 16.0, -44.0, 1.0],
      [1.00, 14.0, -28.0, 0.0],
    ],
    CharacterAnimState.drive: [
      [0.00, 6.0, -30.0, -1.0],
      [0.22, 22.0, -30.0, 0.2],
      [0.60, 10.0, -42.0, 1.2],
      [1.00, 14.0, -28.0, 0.0],
    ],
    CharacterAnimState.smash: [
      [0.00, 12.0, -60.0, -1.2],
      [0.28, 10.0, -74.0, -0.3],
      [0.42, 18.0, -40.0, 1.1],
      [0.70, 16.0, -26.0, 1.3],
      [1.00, 14.0, -28.0, 0.0],
    ],
    CharacterAnimState.slice: [
      [0.00, 22.0, -44.0, -0.9],
      [0.25, 20.0, -26.0, 0.5],
      [0.55, 8.0, -14.0, 1.5],
      [1.00, 14.0, -28.0, 0.0],
    ],
    CharacterAnimState.lob: [
      [0.00, 16.0, -12.0, 0.9],
      [0.25, 20.0, -24.0, 0.4],
      [0.55, 14.0, -62.0, -1.0],
      [1.00, 14.0, -28.0, 0.0],
    ],
  };

  static bool _isAction(CharacterAnimState s) => _swingKeys.containsKey(s);

  static List<double> _swingPose(CharacterAnimState s, double t) {
    final keys = _swingKeys[s];
    if (keys == null) return const [14.0, -28.0, 0.0];
    if (t <= keys.first[0]) return keys.first.sublist(1);
    for (int i = 1; i < keys.length; i++) {
      if (t <= keys[i][0]) {
        final a = keys[i - 1];
        final b = keys[i];
        double u = (t - a[0]) / (b[0] - a[0]);
        u = u * u * (3 - 2 * u);
        return [
          a[1] + (b[1] - a[1]) * u,
          a[2] + (b[2] - a[2]) * u,
          a[3] + (b[3] - a[3]) * u,
        ];
      }
    }
    return keys.last.sublist(1);
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
    required double walkPhase,
    required double moveAmount,
    required double moveX,
    required double actionProgress,
  }) {
    final double side = isPlayer ? 1.0 : -1.0;
    final bool acting = _isAction(animState) && actionProgress < 1.0;
    final double p = acting ? actionProgress : 0.0;
    final double m = moveAmount.clamp(0.0, 1.0).toDouble();
    final Paint skinPaint = Paint()..color = const Color(0xFFFDBA74);

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(scale);

    double jump = 0.0;
    double crouch = 0.0;
    if (acting) {
      switch (animState) {
        case CharacterAnimState.smash:
          jump = sin(pi * p) * 16.0;
          break;
        case CharacterAnimState.lob:
          crouch = p < 0.3 ? 6.0 * (p / 0.3) : 6.0 * (1 - (p - 0.3) / 0.7);
          jump = p > 0.35 ? sin(pi * ((p - 0.35) / 0.65)) * 4.0 : 0.0;
          break;
        case CharacterAnimState.slice:
          crouch = sin(pi * p) * 4.0;
          break;
        case CharacterAnimState.serving:
          jump = sin(pi * p) * 3.0;
          break;
        case CharacterAnimState.drive:
          crouch = sin(pi * p) * 2.5;
          break;
        default:
          break;
      }
    }

    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(0, -1),
          width: 30.0 - jump * 0.6,
          height: 8.0 - jump * 0.15),
      Paint()..color = Colors.black.withOpacity(0.35),
    );

    if (isGlowing) {
      canvas.drawCircle(
        const Offset(0, -34),
        30,
        Paint()
          ..color = const Color(0xFFF97316).withOpacity(0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    final double runBob = -sin(walkPhase * 2.0).abs() * 3.2 * m;
    final double breathe = sin(animClock * 3.0) * 0.8 * (1.0 - m);
    final double bodyY = runBob + breathe - jump + crouch;

    double lean = moveX * 0.16 * m;
    if (acting) {
      final double swingLean = sin(pi * p) * 0.16;
      lean += animState == CharacterAnimState.smash
          ? -side * swingLean * 0.6
          : side * swingLean;
    }
    canvas.rotate(lean);

    final double stride = sin(walkPhase);
    final double liftL = max(0.0, stride) * 5.0 * m;
    final double liftR = max(0.0, -stride) * 5.0 * m;
    final double spreadL = -stride * 2.5 * m;
    final double spreadR = stride * 2.5 * m;
    final double legTop = -12.0 + bodyY;
    final double footL = -2.0 - liftL - jump;
    final double footR = -2.0 - liftR - jump;

    final Paint shoePaint = Paint()..color = const Color(0xFFF4F4F5);
    canvas.drawRRect(
      RRect.fromLTRBR(
          -8 + spreadL, legTop, -3 + spreadL, footL, const Radius.circular(2)),
      skinPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
          3 + spreadR, legTop, 8 + spreadR, footR, const Radius.circular(2)),
      skinPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(-9 + spreadL, footL - 3, -2 + spreadL, footL + 1,
          const Radius.circular(2)),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(2 + spreadR, footR - 3, 9 + spreadR, footR + 1,
          const Radius.circular(2)),
      shoePaint,
    );

    canvas.save();
    canvas.translate(0, bodyY);

    final Offset offShoulder = Offset(-side * 10, -34);
    Offset offHand = Offset(-side * 13 - side * sin(walkPhase) * 1.5 * m,
        -24 - sin(walkPhase) * 4.0 * m);
    if (acting && animState == CharacterAnimState.serving && p < 0.35) {
      offHand = Offset(-side * 8, -58 + p * 20);
    } else if (acting && animState == CharacterAnimState.smash && p < 0.45) {
      offHand = Offset(-side * 9, -62);
    } else if (acting) {
      offHand = Offset(-side * 15, -30 + sin(pi * p) * 6.0);
    }
    _drawArm(canvas, offShoulder, offHand, shirtColor, skinPaint);

    canvas.drawRRect(
      RRect.fromLTRBR(-10, -22, 10, -10, const Radius.circular(4)),
      Paint()..color = const Color(0xFF18181B),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(-11, -38, 11, -20, const Radius.circular(6)),
      Paint()..color = shirtColor,
    );

    final double headTilt =
        acting ? side * sin(pi * p) * 0.10 : moveX * 0.06 * m;
    canvas.save();
    canvas.translate(0, -50);
    canvas.rotate(headTilt);
    canvas.drawCircle(Offset.zero, 16, skinPaint);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, -4), radius: 17),
      3.14,
      3.14,
      true,
      Paint()..color = const Color(0xFF27272A),
    );
    if (!isPlayer) {
      final Paint eye = Paint()..color = const Color(0xFF18181B);
      canvas.drawCircle(const Offset(-5, 2), 1.8, eye);
      canvas.drawCircle(const Offset(5, 2), 1.8, eye);
    }
    canvas.restore();

    List<double> pose;
    if (acting) {
      pose = _swingPose(animState, p);
    } else {
      pose = [
        14.0,
        -28.0 + sin(walkPhase * 2.0) * 1.5 * m,
        sin(walkPhase) * 0.10 * m
      ];
    }
    final Offset hand = Offset(pose[0] * side, pose[1]);
    final double paddleAngle = pose[2] * side;
    final Offset shoulder = Offset(side * 10, -34);

    if (acting && p > 0.08 && p < 0.65) {
      final List<double> prev = _swingPose(animState, max(0.0, p - 0.10));
      canvas.drawLine(
        Offset(prev[0] * side, prev[1] - 8),
        Offset(hand.dx, hand.dy - 8),
        Paint()
          ..color = Colors.white.withOpacity(0.35)
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round,
      );
    }

    _drawArm(canvas, shoulder, hand, shirtColor, skinPaint);

    final double paddleScale = isShrunk ? 0.5 : 1.0;
    canvas.save();
    canvas.translate(hand.dx, hand.dy);
    canvas.rotate(paddleAngle);
    canvas.scale(paddleScale);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 4), width: 3.5, height: 9),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF3F3F46),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -8), width: 15, height: 19),
        const Radius.circular(5),
      ),
      Paint()
        ..color = isGlowing ? const Color(0xFFF97316) : const Color(0xFFEF4444),
    );

    canvas.restore();
    canvas.restore();
    canvas.restore();
  }

  void _drawArm(
      Canvas canvas, Offset shoulder, Offset hand, Color sleeve, Paint skin) {
    final Offset mid = Offset.lerp(shoulder, hand, 0.45)!;
    canvas.drawLine(
      shoulder,
      hand,
      Paint()
        ..color = const Color(0xFFFDBA74)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      shoulder,
      mid,
      Paint()
        ..color = sleeve
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(hand, 2.8, skin);
  }

  @override
  bool shouldRepaint(covariant PerspectiveCourtPainter oldDelegate) => true;
}
