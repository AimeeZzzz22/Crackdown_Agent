import 'dart:async';
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

  String? _savedReply;
  DateTime? _dismissedAt;
  Timer? _clearTimer;

  late final AnimationController _breathe;
  late final AnimationController _slide;
  late final AnimationController _bubble;
  late final Animation<double> _slideAnim;
  late final Animation<double> _bubbleAnim;

  static const _petSize = 200.0;
  static const _peekVisible = 64.0;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _slide = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _slideAnim = CurvedAnimation(parent: _slide, curve: Curves.easeOutBack);
    _bubble = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _bubbleAnim = CurvedAnimation(parent: _bubble, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    _breathe.dispose();
    _slide.dispose();
    _bubble.dispose();
    super.dispose();
  }

  String? get _resumeReply {
    if (_savedReply == null || _dismissedAt == null) return null;
    if (DateTime.now().difference(_dismissedAt!) >= const Duration(seconds: 10)) return null;
    return _savedReply;
  }

  void _onPetTap() {
    if (_petState == _PetState.active) {
      _dismiss(null);
      return;
    }
    setState(() => _petState = _PetState.active);
    _slide.forward().then((_) => _bubble.forward());
  }

  void _dismiss(String? lastReply) {
    _clearTimer?.cancel();
    if (lastReply != null) {
      _savedReply = lastReply;
      _dismissedAt = DateTime.now();
      _clearTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() { _savedReply = null; _dismissedAt = null; });
      });
    }
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
        final isHiding = _petState == _PetState.hiding;

        final hideX = screenW - _petSize;
        final hideY = screenH * 0.52 - _petSize / 2;
        final activeX = screenW / 2 - _petSize / 2;
        final activeY = screenH - navBarH - _petSize - 16;

        final petX = isHiding ? hideX : hideX + (activeX - hideX) * t;
        final petY = isHiding ? hideY : hideY + (activeY - hideY) * t;

        final opacity = isHiding ? 0.35 + 0.25 * _breathe.value : 0.28;

        final petImage = SizedBox(
          width: _petSize,
          height: _petSize,
          child: Image.asset('assets/pet_full.png', fit: BoxFit.contain),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (_petState == _PetState.active)
              Positioned(
                left: (screenW / 2 - 148).clamp(8.0, screenW - 300.0),
                top: petY - 200,
                child: FadeTransition(
                  opacity: _bubbleAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(_bubbleAnim),
                    child: PetChatBubble(
                      initialReply: _resumeReply,
                      onDismiss: _dismiss,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: petX,
              top: petY,
              child: GestureDetector(
                onTap: _onPetTap,
                child: isHiding
                    ? ClipRect(
                        child: Align(
                          alignment: Alignment.centerRight,
                          widthFactor: _peekVisible / _petSize,
                          child: Opacity(opacity: opacity, child: petImage),
                        ),
                      )
                    : Opacity(opacity: opacity, child: petImage),
              ),
            ),
          ],
        );
      },
    );
  }
}
