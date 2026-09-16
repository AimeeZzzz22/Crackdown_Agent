import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/agent_service.dart';

enum _BubblePhase { idle, listening, loading, replied }

class PetChatBubble extends StatefulWidget {
  final VoidCallback onDismiss;
  const PetChatBubble({super.key, required this.onDismiss});

  @override
  State<PetChatBubble> createState() => _PetChatBubbleState();
}

class _PetChatBubbleState extends State<PetChatBubble>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _speech = stt.SpeechToText();
  _BubblePhase _phase = _BubblePhase.idle;
  String _reply = '';
  bool _speechAvailable = false;

  // Ellipsis dots animation
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _toggleListen() async {
    if (!_speechAvailable) return;
    if (_speech.isListening) {
      await _speech.stop();
      setState(() => _phase = _BubblePhase.idle);
    } else {
      setState(() {
        _phase = _BubblePhase.listening;
        _ctrl.clear();
      });
      await _speech.listen(onResult: (r) {
        if (mounted) setState(() => _ctrl.text = r.recognizedWords);
      });
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (_speech.isListening) await _speech.stop();
    setState(() => _phase = _BubblePhase.loading);
    final resp = await AgentService.instance.process(text);
    if (mounted) setState(() {
      _phase = _BubblePhase.replied;
      _reply = resp.reply;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _dots.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _Bubble(child: _body()),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _BubblePhase.loading:
        return _LoadingDots(anim: _dots);
      case _BubblePhase.replied:
        return _ReplyView(text: _reply, onDismiss: widget.onDismiss);
      case _BubblePhase.listening:
      case _BubblePhase.idle:
        return _InputView(
          ctrl: _ctrl,
          isListening: _phase == _BubblePhase.listening,
          speechAvailable: _speechAvailable,
          onListen: _toggleListen,
          onSend: _send,
        );
    }
  }
}

// ── Bubble shell ──────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final Widget child;
  const _Bubble({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF89C4EE).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFBEDEF7), width: 1.5),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: child,
          ),
          // Tail pointing down
          Positioned(
            bottom: -12,
            left: 0,
            right: 0,
            child: Center(
              child: CustomPaint(
                size: const Size(20, 12),
                painter: _TailPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFBEDEF7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_TailPainter _) => false;
}

// ── Sub-views ─────────────────────────────────────────────────────────────────

class _InputView extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isListening;
  final bool speechAvailable;
  final VoidCallback onListen;
  final VoidCallback onSend;

  const _InputView({
    required this.ctrl,
    required this.isListening,
    required this.speechAvailable,
    required this.onListen,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('🐾', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            isListening ? 'Listening…' : 'How can I help?',
            style: GoogleFonts.epilogue(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A4A6E),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isListening
                  ? const Color(0xFF4A90C4)
                  : const Color(0xFFBEDEF7),
            ),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                style: GoogleFonts.epilogue(
                    fontSize: 13, color: const Color(0xFF1A3550)),
                decoration: InputDecoration(
                  hintText: 'Add gym at 6pm…',
                  hintStyle: GoogleFonts.epilogue(
                      fontSize: 13, color: const Color(0xFFAAC8E0)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            if (speechAvailable)
              _CircleBtn(
                icon: isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: isListening ? Colors.red : const Color(0xFF4A90C4),
                onTap: onListen,
                size: 32,
              ),
            _CircleBtn(
              icon: Icons.send_rounded,
              color: const Color(0xFF4A90C4),
              onTap: onSend,
              size: 32,
            ),
            const SizedBox(width: 4),
          ]),
        ),
      ],
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final Animation<double> anim;
  const _LoadingDots({required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (anim.value - i / 3).remainder(1.0);
            final scale = 0.5 + 0.5 * (1 - (phase * 2 - 1).abs().clamp(0, 1));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF89C4EE),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ReplyView extends StatelessWidget {
  final String text;
  final VoidCallback onDismiss;
  const _ReplyView({required this.text, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: GoogleFonts.epilogue(
              fontSize: 13, color: const Color(0xFF1A3550), height: 1.45),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onDismiss,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5BA8D8), Color(0xFF3A80B8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90C4).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text('Done ✓',
                style: GoogleFonts.epilogue(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  const _CircleBtn(
      {required this.icon,
      required this.color,
      required this.onTap,
      required this.size});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: size * 0.55),
        ),
      );
}
