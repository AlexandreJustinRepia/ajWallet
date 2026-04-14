import 'dart:math';
import 'package:flutter/material.dart';
import 'tree_models.dart';
import '../../models/tree_skin.dart';

class TreeStructurePainter extends CustomPainter {
  final List<BranchData> branches;
  final TreeSkinConfig config;
  final double health;
  final double growth;

  TreeStructurePainter({
    required this.branches,
    required this.config,
    required this.health,
    required this.growth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height - 20);

    final paint = Paint()
      ..color = config.trunkColor
      ..strokeCap = config.isTechMode ? StrokeCap.square : StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var branch in branches) {
      paint.strokeWidth = branch.thickness;
      if (config.isTechMode) {
        // Tech Mode: Orthogonal lines
        final path = Path();
        path.moveTo(branch.start.dx, branch.start.dy);
        path.lineTo(branch.end.dx, branch.start.dy);
        path.lineTo(branch.end.dx, branch.end.dy);
        canvas.drawPath(path, paint);
      } else {
        canvas.drawLine(branch.start, branch.end, paint);
      }
    }
    
    // Draw Roots if health is low
    if (health < 0.7) {
       _drawRoots(canvas, Offset.zero, (0.7 - health).clamp(0.0, 1.0), growth);
    }
    canvas.restore();
  }

  void _drawRoots(Canvas canvas, Offset center, double opacity, double growth) {
    final rootPaint = Paint()
      ..color = const Color(0xFF3E2723).withValues(alpha: opacity * 0.6)
      ..strokeWidth = 2.5 * (1.1 - opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final random = Random(42);
    for (int i = 0; i < 4; i++) {
      final angle = pi / 4 + (i * pi / 6) + (random.nextDouble() * 0.2);
      final rootPath = Path();
      rootPath.moveTo(center.dx, center.dy - 3);
      rootPath.quadraticBezierTo(
        center.dx + cos(angle) * 25,
        center.dy + 8,
        center.dx + cos(angle) * 45 * (1.0 + growth * 0.1),
        center.dy + 18,
      );
      canvas.drawPath(rootPath, rootPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TreeStructurePainter oldDelegate) {
    return oldDelegate.branches != branches || 
           oldDelegate.config != config ||
           oldDelegate.health != health;
  }
}

class LeafPainter extends CustomPainter {
  final List<LeafData> leaves;
  final TreeSkinConfig config;
  final double growth;

  LeafPainter({
    required this.leaves,
    required this.config,
    required this.growth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (leaves.isEmpty) return;

    canvas.save();
    canvas.translate(size.width / 2, size.height - 20);
    
    final paint = Paint()..color = config.leafColor.withValues(alpha: 0.75);
    final highlightPaint = Paint()
      ..color = Color.lerp(config.leafColor, Colors.white, 0.15)!.withValues(alpha: 0.4);

    final path = Path();
    final highlightPath = Path();

    for (int i = 0; i < leaves.length; i++) {
      final leaf = leaves[i];
      final rect = Rect.fromCenter(
        center: leaf.position,
        width: leaf.size * 1.6,
        height: leaf.size,
      );

      switch (config.leafShape) {
        case LeafShape.petal:
          _addPetalPath(path, leaf.position, leaf.size);
          break;
        case LeafShape.crystal:
          _addCrystalPath(path, leaf.position, leaf.size);
          break;
        case LeafShape.techSquare:
          path.addRect(rect);
          break;
        case LeafShape.circle:
        default:
          path.addOval(rect);
          break;
      }

      if (i % 3 == 0) {
        highlightPath.addOval(Rect.fromCenter(
          center: leaf.position.translate(1, -1),
          width: leaf.size * 0.8,
          height: leaf.size * 0.4,
        ));
      }
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(highlightPath, highlightPaint);
    canvas.restore();
  }

  void _addPetalPath(Path path, Offset center, double size) {
    final petalPath = Path();
    petalPath.moveTo(center.dx, center.dy + size / 2);
    petalPath.cubicTo(
      center.dx - size, center.dy - size / 2,
      center.dx - size / 4, center.dy - size,
      center.dx, center.dy - size / 4,
    );
    petalPath.cubicTo(
      center.dx + size / 4, center.dy - size,
      center.dx + size, center.dy - size / 2,
      center.dx, center.dy + size / 2,
    );
    path.addPath(petalPath, Offset.zero);
  }

  void _addCrystalPath(Path path, Offset center, double size) {
    final crystalPath = Path();
    crystalPath.moveTo(center.dx, center.dy - size);
    crystalPath.lineTo(center.dx + size * 0.8, center.dy);
    crystalPath.lineTo(center.dx, center.dy + size);
    crystalPath.lineTo(center.dx - size * 0.8, center.dy);
    crystalPath.close();
    path.addPath(crystalPath, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant LeafPainter oldDelegate) {
    return oldDelegate.leaves != leaves || oldDelegate.config != config;
  }
}

class ParticlePainter extends CustomPainter {
  final double incomeProgress;
  final double expenseProgress;
  final TreeSkinConfig config;

  ParticlePainter({
    required this.incomeProgress,
    required this.expenseProgress,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height - 20);
    if (incomeProgress > 0) _drawIncomeParticles(canvas, size, incomeProgress);
    if (expenseProgress > 0) _drawFallingElements(canvas, size, expenseProgress);
    canvas.restore();
  }

  void _drawIncomeParticles(Canvas canvas, Size size, double progress) {
    final color = config.particleColor ?? Colors.lightBlueAccent;
    final particlePaint = Paint()..color = color.withValues(alpha: 0.6);
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = 0; i < 6; i++) {
      final t = (progress * 1.6 - i * 0.12).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1.0) continue;

      final startX = (i - 2.5) * 35;
      final y = -size.height * 0.4 + (size.height * 0.5 * t);
      
      if (config.leafShape == LeafShape.techSquare) {
        canvas.drawRect(Rect.fromCenter(center: Offset(startX, y), width: 5, height: 5), particlePaint);
      } else {
        canvas.drawCircle(Offset(startX, y), 2.5, particlePaint);
      }
      
      if (t > 0.3 && t < 0.7) {
        canvas.drawCircle(Offset(startX, y), 5, glowPaint);
      }
    }
  }

  void _drawFallingElements(Canvas canvas, Size size, double progress) {
    final leafPaint = Paint()..color = config.leafColor.withValues(alpha: 0.6);
    final random = Random(88);

    for (int i = 0; i < 5; i++) {
      final t = (progress * 1.4 - i * 0.18).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1.0) continue;

      final startX = (random.nextDouble() - 0.5) * 120;
      final sway = sin(t * pi * 5 + i) * 25;
      final y = -size.height * 0.2 + (size.height * 0.4 * t);
      
      canvas.save();
      canvas.translate(startX + sway, y);
      canvas.rotate(t * pi * 4 + i);
      
      if (config.leafShape == LeafShape.techSquare) {
        canvas.drawRect(Rect.fromLTWH(-4, -4, 8, 8), leafPaint);
      } else if (config.leafShape == LeafShape.petal) {
         // Tiny petal for falling
         final p = Path();
         p.addOval(Rect.fromLTWH(-4, -2, 8, 4));
         canvas.drawPath(p, leafPaint);
      } else {
        canvas.drawOval(Rect.fromLTWH(-5, -2.5, 10, 5), leafPaint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.incomeProgress != incomeProgress ||
           oldDelegate.expenseProgress != expenseProgress ||
           oldDelegate.config != config;
  }
}
