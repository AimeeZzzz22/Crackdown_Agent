import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/agent_service.dart';

enum BubbleState { idle, listening, loading, replied }

class PetChatBubble extends StatefulWidget {
  final VoidCallback onDismiss;
  const PetChatBubble({super.key, required this.onDismiss});

  @override
  State<PetChatBubble> createState() => _PetChatBubbleState();
}

class _PetChatBubbleState extends State<PetChatBubble> {
  final _controller = TextEditingController();
  final _speech = stt.SpeechToText();
  BubbleState _state = BubbleState.idle;
  String _replyText = '';
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) return;
    if (_speech.isListening) {
      await _speech.stop();
      setState(() => _state = BubbleState.idle);
    } else {
      setState(() {
        _state = BubbleState.listening;
        _controller.clear();
      });
      await _speech.listen(onResult: (result) {
        setState(() => _controller.text = result.recognizedWords);
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_speech.isListening) await _speech.stop();

    setState(() => _state = BubbleState.loading);
    final response = await AgentService.instance.process(text);
    setState(() {
      _state = BubbleState.replied;
      _replyText = response.reply;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: _BubblePainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_state == BubbleState.loading) {
      return SizedBox(
        width: 200,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Thinking…', style: _textStyle()),
          const SizedBox(height: 10),
          const LinearProgressIndicator(
            backgroundColor: Color(0xFFD6EAFB),
            valueColor: AlwaysStoppedAnimation(Color(0xFF4A90C4)),
          ),
        ]),
      );
    }

    if (_state == BubbleState.replied) {
      return SizedBox(
        width: 220,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_replyText,
              style: _textStyle(), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90C4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Done',
                  style: _textStyle().copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      );
    }

    // idle / listening
    return SizedBox(
      width: 240,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _state == BubbleState.listening
                ? 'Listening…'
                : 'What can I help you with?',
            style: _textStyle().copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: _textStyle(size: 13),
                decoration: InputDecoration(
                  hintText: 'Type or tap mic…',
                  hintStyle: _textStyle(size: 13)
                      .copyWith(color: const Color(0xFF88AACB)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFA8D4F5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4A90C4)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 6),
            _IconBtn(
              icon: _state == BubbleState.listening
                  ? Icons.stop_circle_outlined
                  : Icons.mic,
              color: _state == BubbleState.listening
                  ? Colors.red
                  : const Color(0xFF4A90C4),
              onTap: _toggleListening,
            ),
            const SizedBox(width: 4),
            _IconBtn(
              icon: Icons.send_rounded,
              color: const Color(0xFF4A90C4),
              onTap: _send,
            ),
          ]),
        ],
      ),
    );
  }

  TextStyle _textStyle({double size = 14}) => GoogleFonts.epilogue(
        fontSize: size,
        color: const Color(0xFF1A3550),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      );
}

// Speech bubble with tail pointing downward
class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const r = 16.0;
    const tailH = 14.0;
    final w = size.width;
    final h = size.height - tailH;
    final cx = w / 2;

    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(cx + 10, h)
      ..lineTo(cx, h + tailH)
      ..lineTo(cx - 10, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFA8D4F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}
