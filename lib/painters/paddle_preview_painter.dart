import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class PaddlePreviewWidget extends StatelessWidget {
  final PaddleData paddle;
  final double width;
  final double height;

  const PaddlePreviewWidget({
    Key? key,
    required this.paddle,
    this.width = 64,
    this.height = 64,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: PaddlePreviewPainter(paddle: paddle),
    );
  }
}

class PaddlePreviewPainter extends CustomPainter {
  final PaddleData paddle;

  PaddlePreviewPainter({required this.paddle});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);

    // Glow for legendary and above
    if (paddle.rarity.index >= PaddleRarity.legendary.index) {
      canvas.drawCircle(
        const Offset(0, -4),
        size.width * 0.35,
        Paint()
          ..color = paddle.rarity.color.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Grip Handle
    final Paint gripPaint = Paint()..color = const Color(0xFF27272A);
    final RRect handleRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, size.height * 0.28),
        width: size.width * 0.14,
        height: size.height * 0.35,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(handleRRect, gripPaint);

    // Grip Wrapping Detail
    final Paint wrapPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(-size.width * 0.07, size.height * 0.20),
      Offset(size.width * 0.07, size.height * 0.24),
      wrapPaint,
    );
    canvas.drawLine(
      Offset(-size.width * 0.07, size.height * 0.28),
      Offset(size.width * 0.07, size.height * 0.32),
      wrapPaint,
    );

    // Outer Edge Rim
    final RRect outerFace = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -size.height * 0.10),
        width: size.width * 0.62,
        height: size.height * 0.65,
      ),
      Radius.circular(size.width * 0.20),
    );
    canvas.drawRRect(
      outerFace,
      Paint()..color = const Color(0xFF18181B),
    );

    // Main Paddle Face
    final RRect innerFace = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -size.height * 0.10),
        width: size.width * 0.54,
        height: size.height * 0.57,
      ),
      Radius.circular(size.width * 0.16),
    );
    canvas.drawRRect(
      innerFace,
      Paint()..color = paddle.faceColor,
    );

    // Inner Pattern / Rarity Styling
    _drawPattern(canvas, size, innerFace);

    // Rarity Edge Border
    canvas.drawRRect(
      innerFace,
      Paint()
        ..color = paddle.rarity.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    canvas.restore();
  }

  void _drawPattern(Canvas canvas, Size size, RRect bounds) {
    canvas.save();
    canvas.clipRRect(bounds);

    final Paint accentPaint = Paint()
      ..color = paddle.accentColor.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final Offset center = Offset(0, -size.height * 0.10);

    switch (paddle.patternStyle) {
      case 'stripes':
        canvas.drawLine(
          Offset(-size.width * 0.3, center.dy - 10),
          Offset(size.width * 0.3, center.dy + 10),
          accentPaint,
        );
        break;
      case 'ring':
        canvas.drawCircle(center, size.width * 0.15, accentPaint);
        break;
      case 'lightning':
        final Path path = Path()
          ..moveTo(center.dx - 6, center.dy - 14)
          ..lineTo(center.dx + 2, center.dy - 2)
          ..lineTo(center.dx - 4, center.dy)
          ..lineTo(center.dx + 6, center.dy + 14);
        canvas.drawPath(path, accentPaint);
        break;
      case 'star':
        canvas.drawCircle(
            center, size.width * 0.08, Paint()..color = paddle.accentColor);
        break;
      default:
        canvas.drawCircle(
          center,
          size.width * 0.06,
          Paint()..color = paddle.accentColor.withOpacity(0.4),
        );
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PaddlePreviewPainter oldDelegate) {
    return oldDelegate.paddle.id != paddle.id;
  }
}
