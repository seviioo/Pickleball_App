import 'package:flutter/material.dart';

/// ============================================================
/// STREET BLITZ — shared design system
/// Same black / red / gold family as the court, applied
/// consistently across every menu & UI screen.
/// ============================================================

class AppColors {
  AppColors._();

  static const void_ = Color(0xFF050506); // deepest background
  static const ink = Color(0xFF0B0B0D); // base background
  static const surface = Color(0xFF141417); // card surface
  static const surfaceRaised = Color(0xFF1C1C20); // raised card
  static const hairline = Color(0xFF2A2A2F); // borders

  static const gold = Color(0xFFFACC15);
  static const goldDeep = Color(0xFFCA8A04);
  static const red = Color(0xFFDC2626);
  static const redBright = Color(0xFFEF4444);
  static const redDeep = Color(0xFF7F1D1D);

  static const textPrimary = Color(0xFFF4F4F5);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textFaint = Color(0xFF63636B);

  static const win = Color(0xFFA3E635);

  static const LinearGradient goldButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDE047), Color(0xFFEAB308)],
  );

  static const LinearGradient redButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
  );

  static const LinearGradient cardSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1C20), Color(0xFF131316)],
  );

  static RadialGradient spotlight(Color color, {double opacity = 0.18}) {
    return RadialGradient(
      colors: [color.withValues(alpha: opacity), Colors.transparent],
      radius: 1.1,
    );
  }
}

/// Full-bleed background: void black + faint red/gold glows +
/// a subtle diagonal "asphalt" texture so every screen feels
/// like it belongs to the same underground court world.
class StreetBackground extends StatelessWidget {
  final Widget child;
  const StreetBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: AppColors.void_),
        // Top red glow
        Positioned(
          top: -120,
          left: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.spotlight(AppColors.red, opacity: 0.14),
            ),
          ),
        ),
        // Bottom gold glow
        Positioned(
          bottom: -140,
          right: -80,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.spotlight(AppColors.gold, opacity: 0.10),
            ),
          ),
        ),
        // Faint scanline / chain-link texture
        Opacity(
          opacity: 0.035,
          child: CustomPaint(
            painter: _DiagonalLinesPainter(),
            size: Size.infinite,
          ),
        ),
        child,
      ],
    );
  }
}

class _DiagonalLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;
    const gap = 26.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small eyebrow / kicker label, e.g. "STREET TAG", "TARGET SCORE"
class Kicker extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Kicker(this.text,
      {super.key, this.color = AppColors.textFaint, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

/// Standard card container with sheen gradient + hairline border.
class StreetCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;

  const StreetCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor = AppColors.hairline,
    this.borderWidth = 1.2,
    this.onTap,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppColors.cardSheen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: AppColors.gold.withValues(alpha: 0.08),
        highlightColor: AppColors.gold.withValues(alpha: 0.04),
        child: content,
      ),
    );
  }
}

/// Primary CTA — bold gradient pill with glow + press feedback.
class PrimaryCTA extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Gradient gradient;
  final Color glowColor;
  final Color foreground;
  final double height;

  const PrimaryCTA({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = AppColors.goldButton,
    this.glowColor = AppColors.gold,
    this.foreground = Colors.black,
    this.height = 58,
  });

  @override
  State<PrimaryCTA> createState() => _PrimaryCTAState();
}

class _PrimaryCTAState extends State<PrimaryCTA> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _pressed ? 0.18 : 0.34),
                blurRadius: _pressed ? 10 : 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.foreground, size: 22),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.foreground,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary chip-style button used for row actions.
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.accent = AppColors.gold,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular icon badge used across headers/cards.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBadge(
      {super.key,
      required this.icon,
      this.color = AppColors.gold,
      this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.4),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Consistent AppBar treatment for inner screens.
PreferredSizeWidget streetAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        fontSize: 16,
        letterSpacing: 1.0,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    actions: actions,
  );
}
