import 'dart:math';
import 'package:flutter/material.dart';

class LinePetPainter extends CustomPainter {
  final double animPhase; // 0–1, drives slow breathing wobble
  final double eyeOpen;   // 1.0 = fully open, 0.0 = blink closed
  final bool isActive;

  const LinePetPainter({
    required this.animPhase,
    this.eyeOpen = 1.0,
    this.isActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + size.height * 0.04; // slightly below center
    final r = min(cx, cy) * 0.72;

    // ── Drop shadow ───────────────────────────────────────────────────────────
    final shadowPath = _buildBlobPath(cx, cy + 6, r, animPhase);
    canvas.drawShadow(shadowPath, const Color(0x33000000), 10, false);

    // ── Blob ──────────────────────────────────────────────────────────────────
    final blobPath = _buildBlobPath(cx, cy, r, animPhase);

    // Fill with subtle radial gradient
    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: const [Color(0xFFEAF5FD), Color(0xFFBEDEF7)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.2));
    canvas.drawPath(blobPath, fillPaint);

    // Outline — thick, rounded
    canvas.drawPath(
      blobPath,
      Paint()
        ..color = const Color(0xFF89C4EE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // ── Accent dots ON the outline ────────────────────────────────────────────
    _drawAccentDots(canvas, cx, cy, r, animPhase);

    // ── Face ──────────────────────────────────────────────────────────────────
    _drawFace(canvas, cx, cy, r, eyeOpen);
  }

  // 8-lobe organic blob using Catmull-Rom through perturbed points
  Path _buildBlobPath(double cx, double cy, double r, double phase) {
    // Fixed per-lobe size variations for organic feel (not animated)
    const lobeScales = [1.12, 0.88, 1.18, 0.84, 1.10, 0.90, 1.16, 0.86];
    const n = 8;

    // Slow breathing: ±4% pulsation
    final breathe = 1.0 + 0.04 * sin(phase * 2 * pi);

    final pts = List.generate(n, (i) {
      final angle = (2 * pi * i / n) - pi / 2;
      final dist = r * lobeScales[i] * breathe;
      return Offset(cx + cos(angle) * dist, cy + sin(angle) * dist);
    });

    // Catmull-Rom → cubic Bezier
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      final p3 = pts[(i + 2) % n];
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  void _drawAccentDots(
      Canvas canvas, double cx, double cy, double r, double phase) {
    final breathe = 1.0 + 0.04 * sin(phase * 2 * pi);
    const lobeScales = [1.12, 0.88, 1.18, 0.84, 1.10, 0.90, 1.16, 0.86];
    const n = 8;

    // Place dots at lobe 1, 4, 6 (the inward ones — they sit ON the outline)
    final dotLobes = [1, 4, 6];
    final paint = Paint()..color = const Color(0xFF3A80B8);
    for (final li in dotLobes) {
      final angle = (2 * pi * li / n) - pi / 2;
      final dist = r * lobeScales[li] * breathe;
      canvas.drawCircle(
        Offset(cx + cos(angle) * dist, cy + sin(angle) * dist),
        r * 0.095,
        paint,
      );
    }

    // One extra dot inside the body (decorative)
    canvas.drawCircle(
      Offset(cx + r * 0.18, cy + r * 0.38),
      r * 0.10,
      Paint()..color = const Color(0xFF6BAED6),
    );
  }

  void _drawFace(
      Canvas canvas, double cx, double cy, double r, double eyeOpen) {
    // ── Eyes ─────────────────────────────────────────────────────────────────
    final eyeW = r * 0.23;
    final eyeH = r * 0.32 * eyeOpen.clamp(0.06, 1.0); // blink collapses height

    final eyePaint = Paint()..color = const Color(0xFFF5E53A);
    final eyePupilPaint = Paint()..color = const Color(0xFF2A5F8A);

    // Left eye — slightly bigger, tilted left
    canvas.save();
    canvas.translate(cx - r * 0.24, cy - r * 0.10);
    canvas.rotate(-0.22);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: eyeW, height: eyeH),
        eyePaint);
    if (eyeOpen > 0.3) {
      canvas.drawCircle(
          Offset(eyeW * 0.08, -eyeH * 0.08), eyeW * 0.22, eyePupilPaint);
    }
    canvas.restore();

    // Right eye — slightly smaller, tilted right
    canvas.save();
    canvas.translate(cx + r * 0.20, cy - r * 0.16);
    canvas.rotate(0.18);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: eyeW * 0.82, height: eyeH * 0.86),
        eyePaint);
    if (eyeOpen > 0.3) {
      canvas.drawCircle(
          Offset(eyeW * 0.07, -eyeH * 0.07), eyeW * 0.19, eyePupilPaint);
    }
    canvas.restore();

    // ── Nose / mouth dot ─────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx - r * 0.02, cy + r * 0.20),
      r * 0.09,
      Paint()..color = const Color(0xFF5A9EC9),
    );

    // ── Cheek blush (subtle) ──────────────────────────────────────────────────
    final blushPaint = Paint()
      ..color = const Color(0x22FF8CAB)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - r * 0.36, cy + r * 0.10),
            width: r * 0.28,
            height: r * 0.16),
        blushPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + r * 0.33, cy + r * 0.06),
            width: r * 0.24,
            height: r * 0.14),
        blushPaint);
  }

  @override
  bool shouldRepaint(LinePetPainter old) =>
      old.animPhase != animPhase ||
      old.eyeOpen != eyeOpen ||
      old.isActive != isActive;
}
