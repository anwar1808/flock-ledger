import 'package:flutter/material.dart';

/// A simple outlined chicken-coop icon that matches the Material outlined
/// icon style. Picks up colour and size from the surrounding IconTheme.
class CoopIcon extends StatelessWidget {
  const CoopIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final color = theme.color ?? Theme.of(context).colorScheme.onSurface;
    final size = theme.size ?? 24.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CoopPainter(color: color)),
    );
  }
}

class _CoopPainter extends CustomPainter {
  final Color color;
  const _CoopPainter({required this.color});

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

    // ── Roof — peaked triangle ──
    final roof = Path()
      ..moveTo(w * 0.10, h * 0.42)
      ..lineTo(w * 0.50, h * 0.06)
      ..lineTo(w * 0.90, h * 0.42);
    canvas.drawPath(roof, stroke);

    // ── Body — rectangle ──
    canvas.drawRect(
      Rect.fromLTRB(w * 0.10, h * 0.42, w * 0.90, h * 0.92),
      stroke,
    );

    // ── Plank lines inside body (gives it a barn feel) ──
    canvas.drawLine(
        Offset(w * 0.10, h * 0.62), Offset(w * 0.90, h * 0.62), stroke);

    // ── Door — small arch centered in bottom half ──
    final doorLeft = w * 0.38;
    final doorRight = w * 0.62;
    final doorBottom = h * 0.92;
    final doorTop = h * 0.72;
    final door = Path()
      ..moveTo(doorLeft, doorBottom)
      ..lineTo(doorLeft, doorTop + (doorRight - doorLeft) / 2)
      ..arcToPoint(
        Offset(doorRight, doorTop + (doorRight - doorLeft) / 2),
        radius: Radius.circular((doorRight - doorLeft) / 2),
        clockwise: false,
      )
      ..lineTo(doorRight, doorBottom);
    canvas.drawPath(door, stroke);

    // ── Small perch line above door ──
    canvas.drawLine(
        Offset(w * 0.30, h * 0.54), Offset(w * 0.70, h * 0.54), stroke);

    // ── Roost circle (tiny round window in gable) ──
    canvas.drawCircle(Offset(w * 0.50, h * 0.28), w * 0.07, stroke);
  }

  @override
  bool shouldRepaint(_CoopPainter old) => old.color != color;
}
