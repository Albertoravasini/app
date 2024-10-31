// progress_border.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class ProgressBorder extends StatelessWidget {
  final Widget child;
  final double progress;
  final double borderWidth;
  final Color borderColor;
  final BorderRadius borderRadius;

  const ProgressBorder({
    required this.child,
    required this.progress,
    this.borderWidth = 5.0,
    this.borderColor = Colors.yellowAccent,
    this.borderRadius = BorderRadius.zero,
  });

  @override
Widget build(BuildContext context) {
  return TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0.0, end: progress),
    duration: const Duration(milliseconds: 100), // Durata breve per un aggiornamento fluido
    builder: (context, animatedProgress, child) {
      // Cambia il colore e lo spessore del bordo al completamento del progresso
      final currentBorderColor = animatedProgress >= 1.0 ? Colors.yellowAccent : borderColor;
      final currentBorderWidth = animatedProgress >= 1.0 ? borderWidth + 2.0 : borderWidth;

      return CustomPaint(
        painter: _BorderPainter(
          progress: animatedProgress,
          borderWidth: currentBorderWidth,
          borderColor: currentBorderColor,
          borderRadius: borderRadius,
        ),
        child: child,
      );
    },
    child: child,
  );
}}

class _BorderPainter extends CustomPainter {
  final double progress;
  final double borderWidth;
  final Color borderColor;
  final BorderRadius borderRadius;

  _BorderPainter({
    required this.progress,
    required this.borderWidth,
    required this.borderColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Definisce il rettangolo e la cornice esterna
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    RRect outer = borderRadius.toRRect(rect);
    
    // Calcola il percorso a partire dal centro superiore
    Path path = Path();
    double halfWidth = size.width / 2;
    path.moveTo(halfWidth, 0); // Inizia dal centro superiore
    path.lineTo(size.width - borderRadius.topRight.x, 0);

    // Traccia l'arco in alto a destra e segue il bordo
    path.arcToPoint(
      Offset(size.width, borderRadius.topRight.y),
      radius: borderRadius.topRight,
      clockwise: true,
    );
    path.lineTo(size.width, size.height - borderRadius.bottomRight.y);
    path.arcToPoint(
      Offset(size.width - borderRadius.bottomRight.x, size.height),
      radius: borderRadius.bottomRight,
      clockwise: true,
    );
    path.lineTo(borderRadius.bottomLeft.x, size.height);
    path.arcToPoint(
      Offset(0, size.height - borderRadius.bottomLeft.y),
      radius: borderRadius.bottomLeft,
      clockwise: true,
    );
    path.lineTo(0, borderRadius.topLeft.y);
    path.arcToPoint(
      Offset(borderRadius.topLeft.x, 0),
      radius: borderRadius.topLeft,
      clockwise: true,
    );
    path.lineTo(halfWidth, 0); // Torna al centro superiore

    // Applica il progresso al percorso
    PathMetrics pathMetrics = path.computeMetrics();
    Path partialPath = Path();

    for (PathMetric metric in pathMetrics) {
      double extractLength = metric.length * progress;
      partialPath.addPath(metric.extractPath(0, extractLength), Offset.zero);
    }

    // Disegna il percorso parziale sul canvas
    canvas.drawPath(partialPath, paint);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}