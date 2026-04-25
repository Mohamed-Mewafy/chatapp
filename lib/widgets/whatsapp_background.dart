import 'package:flutter/material.dart';

class WhatsAppBackground extends StatelessWidget {
  const WhatsAppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0F2F5), Color(0xFFE8E9EB), Color(0xFFF5F6F6)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: WhatsAppPatternPainter(),
        size: Size.infinite,
        child: child,
      ),
    );
  }
}

class WhatsAppPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final double gridSize = 40;
    final double dotSize = 2;

    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
