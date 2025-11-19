import 'package:flutter/material.dart';

class DotGridBackground extends StatelessWidget {
  const DotGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DotGridPainter(),
      child: Container(),
    );
  }
}

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dotSize = 1.0;
    const spacing = 16.0;

    // Create radial gradient mask effect
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.7;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final point = Offset(x, y);
        final distance = (point - center).distance;
        
        // Fade out dots near edges (radial gradient effect)
        final opacity = 1.0 - (distance / radius).clamp(0.0, 1.0);
        
        if (opacity > 0) {
          final dotPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.1 * opacity)
            ..style = PaintingStyle.fill;
          
          canvas.drawCircle(point, dotSize, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

