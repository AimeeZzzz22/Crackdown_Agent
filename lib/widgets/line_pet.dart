import 'dart:math';
import 'package:flutter/material.dart';
import 'line_pet_painter.dart';
import 'pet_chat_bubble.dart';

enum _PetState { hiding, active }

class LinePet extends StatefulWidget {
  const LinePet({super.key});

  @override
  State<LinePet> createState() => _LinePetState();
}

class _LinePetState extends State<LinePet> with TickerProviderStateMixin {
  _PetState _petState = _PetState.hiding;

  late final AnimationController _breathe; // slow idle wobble
  late final AnimationController _slide;   // hiding ↔ active transition
  late final AnimationController _blink;   // eye blink
  late final AnimationController _bubble;  // bubble fade-in

  late final Animation<double> _slideAnim;
  late final Animation<double> _bubbleAnim;

  double _eyeOpen = 1.0;
  final _rng = Random();

  static const _petSize = 130.0;
  static const _peekVisible = 48.0; // px visible when hiding

  @override
  void initState() {
    super.initState();

    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _slideAnim = CurvedAnimation(parent: _slide, curve: Curves.easeOutBack);

    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )
      ..addStatusListener(_onBlinkStatus)
      ..addListener(() => setState(() => _eyeOpen = 1.0 - _blink.value));

    _bubble = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bubbleAnim = CurvedAnimation(parent: _bubble, curve: Curves.easeOut);

    _scheduleNextBlink();
  }

  void _scheduleNextBlink() {
    final delay = Duration(milliseconds: 2500 + _rng.nextInt(3000));
    Future.delayed(delay, () {
      if (mounted) _blink.forward();
    });
  }

  void _onBlinkStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _blink.reverse().then((_) {
        if (mounted) _scheduleNextBlink();
      });
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    _slide.dispose();
    _blink.dispose();
    _bubble.dispose();
    super.dispose();
  }

  void _onPetTap() {
    if (_petState != _PetState.hiding) return;
    setState(() => _petState = _PetState.active);
    _slide.forward().then((_) => _bubble.forward());
  }

  void _dismiss() {
    _bubble.reverse().then((_) {
      _slide.reverse().then((_) {
        if (mounted) setState(() => _petState = _PetState.hiding);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    const navBarH = 64.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_breathe, _slideAnim, _bubbleAnim]),
      builder: (context, _) {
        final t = _slideAnim.value;

        // Hiding: mostly off right edge, vertically at 55%
        final hideX = screenW - _peekVisible;
        final hideY = screenH * 0.52 - _petSize / 2;

        // Active: horizontally centered, above nav bar
        final activeX = screenW / 2 - _petSize / 2;
        final activeY = screenH - navBarH - _petSize - 16;

        final petX = hideX + (activeX - hideX) * t;
        final petY = hideY + (activeY - hideY) * t;

        // Subtle bounce scale when entering
        final scale = _petState == _PetState.hiding
            ? 1.0
            : 0.85 + 0.15 * _slideAnim.value;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Chat bubble (fades in after pet arrives) ──────────────────────
            if (_petState == _PetState.active)
              Positioned(
                left: (screenW / 2 - 148).clamp(8.0, screenW - 300.0),
                top: petY - 195,
                child: FadeTransition(
                  opacity: _bubbleAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(_bubbleAnim),
                    child: PetChatBubble(onDismiss: _dismiss),
                  ),
                ),
              ),

            // ── Pet ───────────────────────────────────────────────────────────
            Positioned(
              left: petX,
              top: petY,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: t < 0.05
                      ? _peekVisible / _petSize // clip to peek when hiding
                      : null,
                  child: GestureDetector(
                    onTap: _petState == _PetState.hiding ? _onPetTap : null,
                    child: Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: _petSize,
                        height: _petSize,
                        child: CustomPaint(
                          painter: LinePetPainter(
                            animPhase: _breathe.value,
                            eyeOpen: _eyeOpen,
                            isActive: _petState == _PetState.active,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
