import 'package:flutter/material.dart';
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
  late final AnimationController _bubble;  // bubble fade-in

  late final Animation<double> _slideAnim;
  late final Animation<double> _bubbleAnim;

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

    _bubble = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bubbleAnim = CurvedAnimation(parent: _bubble, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _breathe.dispose();
    _slide.dispose();
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

        // Hiding: pet right edge flush with screen right, clipped to _peekVisible px
        // position left so right edge = screenW → left = screenW - petSize
        final hideX = screenW - _petSize;
        final hideY = screenH * 0.52 - _petSize / 2;

        // Active: horizontally centered, above nav bar
        final activeX = screenW / 2 - _petSize / 2;
        final activeY = screenH - navBarH - _petSize - 16;

        final petX = hideX + (activeX - hideX) * t;
        final petY = hideY + (activeY - hideY) * t;

        final scale = 1.0;

        final isHiding = t < 0.05;

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
                  // Hiding: show right side of image (character face peeks in)
                  // Active: show full image centered
                  alignment: isHiding ? Alignment.centerRight : Alignment.center,
                  widthFactor: isHiding ? _peekVisible / _petSize : null,
                  child: GestureDetector(
                    onTap: _petState == _PetState.hiding ? _onPetTap : null,
                    child: Opacity(
                      opacity: isHiding
                          ? 0.55 + 0.45 * _breathe.value  // gentle pulse while hiding
                          : 0.88,                          // mostly solid when active
                      child: SizedBox(
                        width: _petSize,
                        height: _petSize,
                        child: Image.asset(
                          'assets/pet_full.png',
                          fit: BoxFit.contain,
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
