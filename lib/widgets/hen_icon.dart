import 'package:flutter/material.dart';

/// A simple outlined hen icon that matches the Material outlined icon style.
/// Picks up colour and size automatically from the surrounding IconTheme,
/// so it works seamlessly inside NavigationBar destinations.
class HenIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  const HenIcon({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final color = this.color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    final size = this.size ?? theme.size ?? 24.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HenPainter(color: color)),
    );
  }
}

class _HenPainter extends CustomPainter {
  final Color color;
  const _HenPainter({required this.color});

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

    // ── Body — wide oval in lower portion ──
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.44, h * 0.64),
        width: w * 0.56,
        height: h * 0.42,
      ),
      stroke,
    );

    // ── Head — circle upper right ──
    canvas.drawCircle(Offset(w * 0.65, h * 0.27), w * 0.155, stroke);

    // ── Comb — two small bumps above head ──
    final comb = Path()
      ..moveTo(w * 0.575, h * 0.135)
      ..quadraticBezierTo(w * 0.573, h * 0.045, w * 0.628, h * 0.128)
      ..quadraticBezierTo(w * 0.633, h * 0.038, w * 0.688, h * 0.128);
    canvas.drawPath(comb, stroke);

    // ── Beak — small filled triangle ──
    final beak = Path()
      ..moveTo(w * 0.798, h * 0.255)
      ..lineTo(w * 0.92, h * 0.278)
      ..lineTo(w * 0.798, h * 0.305)
      ..close();
    canvas.drawPath(beak, fill);

    // ── Tail — curved feather bump on left ──
    final tail = Path()
      ..moveTo(w * 0.165, h * 0.535)
      ..quadraticBezierTo(w * 0.005, h * 0.455, w * 0.028, h * 0.632)
      ..quadraticBezierTo(w * 0.005, h * 0.775, w * 0.165, h * 0.730);
    canvas.drawPath(tail, stroke);

    // ── Legs ──
    canvas.drawLine(
        Offset(w * 0.37, h * 0.855), Offset(w * 0.33, h * 0.965), stroke);
    canvas.drawLine(
        Offset(w * 0.50, h * 0.855), Offset(w * 0.545, h * 0.965), stroke);

    // ── Feet — horizontal T-bars ──
    canvas.drawLine(
        Offset(w * 0.245, h * 0.965), Offset(w * 0.415, h * 0.965), stroke);
    canvas.drawLine(
        Offset(w * 0.455, h * 0.965), Offset(w * 0.635, h * 0.965), stroke);
  }

  @override
  bool shouldRepaint(_HenPainter old) => old.color != color;
}
