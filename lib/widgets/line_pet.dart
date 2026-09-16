import 'package:flutter/material.dart';
import 'line_pet_painter.dart';
import 'pet_chat_bubble.dart';

enum _PetState { hiding, active }

class LinePet extends StatefulWidget {
  const LinePet({super.key});

  @override
  State<LinePet> createState() => _LinePetState();
}

class _LinePetState extends State<LinePet>
    with TickerProviderStateMixin {
  _PetState _petState = _PetState.hiding;
  late final AnimationController _wobble;
  late final AnimationController _slide;
  late final Animation<double> _slideAnim;

  // Pet size
  static const _petSize = 110.0;
  // How much of the pet shows when hiding (peek from right)
  static const _peekVisible = 42.0;

  @override
  void initState() {
    super.initState();
    _wobble = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _slideAnim = CurvedAnimation(parent: _slide, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _wobble.dispose();
    _slide.dispose();
    super.dispose();
  }

  void _onPetTap() {
    if (_petState == _PetState.hiding) {
      setState(() => _petState = _PetState.active);
      _slide.forward();
    }
  }

  void _dismiss() {
    _slide.reverse().then((_) {
      if (mounted) setState(() => _petState = _PetState.hiding);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final navBarH = 70.0; // approximate nav bar height

    return AnimatedBuilder(
      animation: Listenable.merge([_wobble, _slideAnim]),
      builder: (context, _) {
        // Interpolate pet position
        // Hiding: right edge, vertically centered-ish
        // Active: center-bottom, above nav bar
        final hideX = screenW - _peekVisible;
        final hideY = screenH * 0.5 - _petSize / 2;
        final activeX = screenW / 2 - _petSize / 2;
        final activeY = screenH - navBarH - _petSize - 20;

        final t = _slideAnim.value;
        final petX = hideX + (activeX - hideX) * t;
        final petY = hideY + (activeY - hideY) * t;

        final showBubble = _petState == _PetState.active && t > 0.6;

        return Stack(
          children: [
            // Bubble — above pet when active
            if (showBubble)
              Positioned(
                left: (screenW / 2 - 140).clamp(8.0, screenW - 280),
                top: petY - 180,
                child: PetChatBubble(onDismiss: _dismiss),
              ),

            // Pet
            Positioned(
              left: petX,
              top: petY,
              child: GestureDetector(
                onTap: _petState == _PetState.hiding ? _onPetTap : null,
                child: SizedBox(
                  width: _petSize,
                  height: _petSize,
                  child: CustomPaint(
                    painter: LinePetPainter(
                      animPhase: _wobble.value,
                      isActive: _petState == _PetState.active,
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
