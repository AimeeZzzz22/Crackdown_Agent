import 'dart:math';
import 'package:flutter/material.dart';

class LinePetPainter extends CustomPainter {
  final double animPhase; // 0.0–1.0, drives wobble
  final bool isActive;

  LinePetPainter({required this.animPhase, this.isActive = false});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy) * 0.78;

    // ── Build wavy blob path ──────────────────────────────────────────────────
    final path = Path();
    const points = 12;
    final List<Offset> vertices = [];

    for (int i = 0; i < points; i++) {
      final angle = (2 * pi * i / points) - pi / 2;
      // Wobble: alternate lobes push in/out, animated
      final wobble = (i % 2 == 0 ? 1.0 : -1.0) * 0.08 * sin(animPhase * 2 * pi + i);
      final dist = r * (1.0 + wobble);
      vertices.add(Offset(cx + cos(angle) * dist, cy + sin(angle) * dist));
    }

    // Draw smooth curve through vertices using cubic bezier
    path.moveTo(vertices[0].dx, vertices[0].dy);
    for (int i = 0; i < points; i++) {
      final p0 = vertices[i];
      final p1 = vertices[(i + 1) % points];
      final cp1 = Offset(
        p0.dx + (p1.dx - vertices[(i - 1 + points) % points].dx) / 4.5,
        p0.dy + (p1.dy - vertices[(i - 1 + points) % points].dy) / 4.5,
      );
      final cp2 = Offset(
        p1.dx - (vertices[(i + 2) % points].dx - p0.dx) / 4.5,
        p1.dy - (vertices[(i + 2) % points].dy - p0.dy) / 4.5,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }
    path.close();

    // ── Fill ─────────────────────────────────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD6EAFB)
        ..style = PaintingStyle.fill,
    );

    // ── Outline ───────────────────────────────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFA8D4F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Eyes ──────────────────────────────────────────────────────────────────
    final eyePaint = Paint()..color = const Color(0xFFF5E642);
    // Left eye
    canvas.save();
    canvas.translate(cx - r * 0.28, cy - r * 0.12);
    canvas.rotate(-0.25);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.22, height: r * 0.32),
      eyePaint,
    );
    canvas.restore();
    // Right eye
    canvas.save();
    canvas.translate(cx + r * 0.22, cy - r * 0.18);
    canvas.rotate(0.2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.18, height: r * 0.28),
      eyePaint,
    );
    canvas.restore();

    // ── Nose (small blue dot) ─────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx - r * 0.04, cy + r * 0.18),
      r * 0.1,
      Paint()..color = const Color(0xFF6BAED6),
    );

    // ── Accent dots on outline ────────────────────────────────────────────────
    final accentPaint = Paint()..color = const Color(0xFF3A7BAF);
    final accentAngles = [-pi / 2 + 0.3, pi / 4, pi + 0.4];
    for (final a in accentAngles) {
      final ax = cx + cos(a) * r;
      final ay = cy + sin(a) * r;
      canvas.drawCircle(Offset(ax, ay), r * 0.09, accentPaint);
    }
  }

  @override
  bool shouldRepaint(LinePetPainter old) =>
      old.animPhase != animPhase || old.isActive != isActive;
}
