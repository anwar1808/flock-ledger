import 'package:flutter/material.dart';

/// Chicken skull icon — outlined style, matches HenIcon's visual weight.
class SkullIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  const SkullIcon({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final c = color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    final s = size ?? theme.size ?? 24.0;
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(painter: _SkullPainter(color: c)),
    );
  }
}

class _SkullPainter extends CustomPainter {
  final Color color;
  const _SkullPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // ── Cranium — egg-shaped oval (wider at top) ──
    final cranium = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(w * 0.46, h * 0.40),
        width: w * 0.66,
        height: h * 0.62,
      ));
    canvas.drawPath(cranium, stroke);

    // ── Eye sockets — two filled circles ──
    canvas.drawCircle(Offset(w * 0.305, h * 0.385), w * 0.095, fill);
    canvas.drawCircle(Offset(w * 0.615, h * 0.385), w * 0.095, fill);

    // ── Beak — small pointed triangle to the right ──
    final beak = Path()
      ..moveTo(w * 0.74, h * 0.565)
      ..lineTo(w * 0.94, h * 0.60)
      ..lineTo(w * 0.74, h * 0.635)
      ..close();
    canvas.drawPath(beak, stroke);

    // ── Jaw line ──
    final jawY = h * 0.685;
    canvas.drawLine(Offset(w * 0.17, jawY), Offset(w * 0.74, jawY), stroke);

    // ── Teeth — three short downward lines ──
    for (int i = 0; i < 3; i++) {
      final x = w * (0.27 + i * 0.155);
      canvas.drawLine(Offset(x, jawY), Offset(x, jawY + h * 0.105), stroke);
    }
  }

  @override
  bool shouldRepaint(_SkullPainter old) => old.color != color;
}
