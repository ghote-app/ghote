import 'package:flutter/material.dart';

class DotGridBackground extends StatelessWidget {
  const DotGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DotGridPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dotSize = 1.0;
    const spacing = 16.0;

    // Use the actual size passed in, don't hardcode 10000
    final maxHeight = size.height; 
    
    final center = Offset(size.width / 2, size.height / 2);
    // Make radius slightly larger to cover corners
    final radius = size.width * 0.8; 

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < maxHeight; y += spacing) {
        final point = Offset(x, y);
        final distance = (point - center).distance;
        
        final opacity = 1.0 - (distance / radius).clamp(0.0, 1.0);
        
        if (opacity > 0.05) { // Optimization: Don't paint invisible dots
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

