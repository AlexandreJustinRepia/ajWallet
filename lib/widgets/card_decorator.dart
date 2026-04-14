import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';

class CardDecorator extends StatelessWidget {
  final Widget child;

  const CardDecorator({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: UserProfileService.profileNotifier,
      builder: (context, profile, _) {
        final activeSkin = profile?.activeCardSkinId;

        if (activeSkin == null) {
          return child;
        }

        return Stack(
          fit: StackFit.passthrough,
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SkinPainter(skinId: activeSkin),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SkinPainter extends CustomPainter {
  final String skinId;

  SkinPainter({required this.skinId});

  @override
  void paint(Canvas canvas, Size size) {
    switch (skinId) {
      case 'skin_nature_vines':
        _paintVines(canvas, size);
        break;
      case 'skin_neon_pulse':
        _paintNeon(canvas, size);
        break;
      case 'skin_royal_gold':
        _paintRoyal(canvas, size);
        break;
    }
  }

  void _paintVines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withValues(alpha:0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Top-left vine
    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.1, size.width * 0.3, 0);
    canvas.drawPath(path1, paint);

    // Bottom-right vine
    final path2 = Path()
      ..moveTo(size.width, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.9, size.width * 0.7, size.height);
    canvas.drawPath(path2, paint);

    // Leaves
    final leafPaint = Paint()
      ..color = Colors.green.withValues(alpha:0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.1), 4, leafPaint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.9), 4, leafPaint);
  }

  void _paintNeon(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha:0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4.0);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    canvas.drawRRect(rect, paint);
    
    final innerPaint = Paint()
      ..color = Colors.pinkAccent.withValues(alpha:0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rect, innerPaint);
  }

  void _paintRoyal(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha:0.6) // Gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(18),
    );
    canvas.drawRRect(rect, paint);
    
    // Corner accents
    final cornerPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha:0.9)
      ..style = PaintingStyle.fill;
    
    double l = 10.0;
    // TL
    canvas.drawRect(Rect.fromLTWH(0, 5, 2, l), cornerPaint);
    canvas.drawRect(Rect.fromLTWH(5, 0, l, 2), cornerPaint);
    // TR
    canvas.drawRect(Rect.fromLTWH(size.width - 2, 5, 2, l), cornerPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - 5 - l, 0, l, 2), cornerPaint);
    // BL
    canvas.drawRect(Rect.fromLTWH(0, size.height - 5 - l, 2, l), cornerPaint);
    canvas.drawRect(Rect.fromLTWH(5, size.height - 2, l, 2), cornerPaint);
    // BR
    canvas.drawRect(Rect.fromLTWH(size.width - 2, size.height - 5 - l, 2, l), cornerPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - 5 - l, size.height - 2, l, 2), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as SkinPainter).skinId != skinId;
  }
}
