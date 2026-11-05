import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Minimal Aesthetic BusSense AI Brand Logo Widget
/// Renders a modern geometric bus silhouette with electric mint sensor radar waves.
class BusSenseLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? backgroundColor;

  const BusSenseLogo({
    super.key,
    this.size = 48,
    this.showWordmark = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.65, size * 0.65),
          painter: _BusSenseLogoPainter(),
        ),
      ),
    );

    if (!showWordmark) {
      return iconWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        SizedBox(width: size * 0.25),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'KOCHI, KERALA',
                  style: TextStyle(
                    fontSize: (size * 0.2).clamp(9.0, 11.0),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            Text(
              'BusSense AI',
              style: TextStyle(
                fontSize: (size * 0.38).clamp(16.0, 22.0),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.primary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BusSenseLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final mintPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final strokeMint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    final strokeEmerald = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;

    // 1. Radar wave arch (top)
    final radarRect = Rect.fromCircle(center: Offset(w * 0.5, h * 0.28), radius: w * 0.22);
    canvas.drawArc(radarRect, 3.5, 2.4, false, strokeMint);

    final radarRectOuter = Rect.fromCircle(center: Offset(w * 0.5, h * 0.30), radius: w * 0.34);
    canvas.drawArc(radarRectOuter, 3.6, 2.2, false, strokeEmerald);

    // Antenna beacon dot
    canvas.drawCircle(Offset(w * 0.5, h * 0.28), w * 0.045, mintPaint);

    // 2. Bus Body (Rounded rectangular chassis)
    final busRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.32, w * 0.76, h * 0.58),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(busRect, whitePaint);

    // 3. Panoramic Windshield (Dark cutout)
    final wsRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.38, w * 0.60, h * 0.24),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(wsRect, darkPaint);

    // Windshield route/telemetry indicator pill (Mint)
    final routePill = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.35, h * 0.41, w * 0.30, h * 0.04),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(routePill, mintPaint);

    // 4. Dual Headlights (Electric Mint)
    canvas.drawCircle(Offset(w * 0.26, h * 0.70), w * 0.06, mintPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.70), w * 0.06, mintPaint);

    // 5. Center Radar/Sensor Badge on grille
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.40, h * 0.68, w * 0.20, h * 0.05),
      Radius.circular(w * 0.025),
    );
    canvas.drawRRect(badgeRect, darkPaint);

    // 6. Wheels (bottom tabs)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, h * 0.88, w * 0.14, h * 0.08),
        Radius.circular(w * 0.03),
      ),
      whitePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.66, h * 0.88, w * 0.14, h * 0.08),
        Radius.circular(w * 0.03),
      ),
      whitePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

