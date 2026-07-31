import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../models/goal_model.dart';
import '../services/app_state.dart';
import 'goal_detail_screen.dart';
import 'new_goal_screen.dart';

class GoalBoardScreen extends StatefulWidget {
  const GoalBoardScreen({super.key});

  @override
  State<GoalBoardScreen> createState() => _GoalBoardScreenState();
}

class _GoalBoardScreenState extends State<GoalBoardScreen> {
  List<GoalModel> get _goals => AppState.instance.goals;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCalendarBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Goal Board',
                  style: GoogleFonts.merriweather(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Productivity Brief chart card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Productivity Brief',
                        style: GoogleFonts.epilogue(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Legend
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: _goals
                          .map((g) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: g.color,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(g.name,
                                      style: GoogleFonts.epilogue(
                                          fontSize: 11,
                                          color: Colors.black54)),
                                ],
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: CustomPaint(
                        size: const Size(double.infinity, 120),
                        painter: _LineChartPainter(goals: _goals),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // X-axis labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['20','21','22','23','24','25','27','28','29','30','1']
                          .map((d) => Text(d,
                              style: GoogleFonts.epilogue(
                                  fontSize: 9, color: Colors.black45)))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Goal rows — alternating layout
              ..._goals.asMap().entries.map((entry) {
                final i = entry.key;
                final goal = entry.value;
                final goalLeft = i % 2 == 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GoalRow(
                    goal: goal,
                    goalOnLeft: goalLeft,
                    onOpenGoal: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GoalDetailScreen(goal: goal)),
                    ),
                    onTaskToggle: (taskIndex) => setState(() {
                      goal.tasks[taskIndex].completed =
                          !goal.tasks[taskIndex].completed;
                    }),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Line Chart Painter ────────────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<GoalModel> goals;
  _LineChartPainter({required this.goals});

  @override
  void paint(Canvas canvas, Size size) {
    for (final goal in goals) {
      final paint = Paint()
        ..color = goal.color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final data = goal.chartData;
      if (data.isEmpty) continue;

      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final x = i / (data.length - 1) * size.width;
        final y = (1 - data[i]) * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          // Smooth curve
          final prevX = (i - 1) / (data.length - 1) * size.width;
          final prevY = (1 - data[i - 1]) * size.height;
          final cpX = (prevX + x) / 2;
          path.cubicTo(cpX, prevY, cpX, y, x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Goal Row ──────────────────────────────────────────────────────────────────

class _GoalRow extends StatelessWidget {
  final GoalModel goal;
  final bool goalOnLeft;
  final VoidCallback onOpenGoal;
  final ValueChanged<int> onTaskToggle;

  const _GoalRow({
    required this.goal,
    required this.goalOnLeft,
    required this.onOpenGoal,
    required this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
    final goalCard = _GoalCard(goal: goal, onOpen: onOpenGoal);
    final taskList = _GoalTaskList(goal: goal, onToggle: onTaskToggle);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: goalOnLeft
          ? [
              Expanded(flex: 5, child: goalCard),
              const SizedBox(width: 8),
              Expanded(flex: 5, child: taskList),
            ]
          : [
              Expanded(flex: 5, child: taskList),
              const SizedBox(width: 8),
              Expanded(flex: 5, child: goalCard),
            ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onOpen;

  const _GoalCard({required this.goal, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: goal.color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.name,
            style: GoogleFonts.merriweather(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Time',
                  style: GoogleFonts.epilogue(
                      fontSize: 11, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(goal.timePercent * 100).round()}%',
                  style: GoogleFonts.epilogue(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 2),
          _ProgressBar(value: goal.timePercent),
          Align(
            alignment: Alignment.centerRight,
            child: Text(goal.endDate,
                style: GoogleFonts.epilogue(
                    fontSize: 10, color: Colors.black54)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('🔥 ${goal.streakDays} Days',
                style: GoogleFonts.epilogue(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onOpen,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text('Open Goal',
                    style: GoogleFonts.epilogue(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTaskList extends StatelessWidget {
  final GoalModel goal;
  final ValueChanged<int> onToggle;

  const _GoalTaskList({required this.goal, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: goal.tasks.asMap().entries.map((e) {
        final task = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: () => onToggle(e.key),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            task.completed
                                ? Icons.check_circle_outline
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: task.completed
                                ? goal.color
                                : Colors.black45,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(task.title,
                                style: GoogleFonts.epilogue(
                                  fontSize: 12,
                                  color: Colors.black,
                                  decoration: task.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 5,
                    height: 40,
                    decoration: BoxDecoration(
                      color: goal.color,
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            height: 8,
            width: constraints.maxWidth * value,
            decoration: BoxDecoration(
              color: const Color(0xFF9B7EC8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Positioned(
            left: constraints.maxWidth * value - 6,
            top: 8,
            child: const Icon(Icons.arrow_drop_up,
                size: 14, color: Color(0xFF9B7EC8)),
          ),
        ],
      );
    });
  }
}
