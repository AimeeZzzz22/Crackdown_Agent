import 'dart:async';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
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

        // Hiding: clip widget right edge flush with screen right
        final hideX = screenW - _peekVisible;
        final hideY = screenH * 0.52 - _petSize / 2;
        // Active: slide in from right, land centered above nav bar
        final slideStartX = screenW - _petSize;
        final activeX = screenW / 2 - _petSize / 2;
        final activeY = screenH - navBarH - _petSize - 16;

        final petX = isHiding ? hideX : slideStartX + (activeX - slideStartX) * t;
        final petY = isHiding ? hideY : hideY + (activeY - hideY) * t;

        // Pulse opacity on outline while hiding; full opacity in active mode
        final opacity = isHiding ? 0.55 + 0.45 * _breathe.value : 1.0;

        // 3D model viewer — transparent background, auto-rotate when active
        final petModel = SizedBox(
          width: _petSize,
          height: _petSize,
          child: ModelViewer(
            src: Uri.base.resolve('assets/assets/pet_3d.glb').toString(),
            alt: 'Line pet',
            autoPlay: true,
            autoRotate: !isHiding,
            autoRotateDelay: 0,
            rotationPerSecond: '20deg',
            cameraControls: false,
            disablePan: true,
            disableZoom: true,
            backgroundColor: Colors.transparent,
            // Keep a fixed camera angle so the character faces forward
            cameraOrbit: '0deg 75deg 2.5m',
          ),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Chat bubble ──────────────────────────────────────────────────
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

            // ── 3D Pet ───────────────────────────────────────────────────────
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
                          child: Opacity(opacity: opacity, child: petModel),
                        ),
                      )
                    : Opacity(opacity: opacity, child: petModel),
              ),
            ),
          ],
        );
      },
    );
  }
}
