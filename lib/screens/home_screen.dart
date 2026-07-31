import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'goal_board_screen.dart';
import 'profile_screen.dart';
import 'planning_screen.dart';
import 'setting_screen.dart';
import '../theme/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    CalendarScreen(),
    GoalBoardScreen(),
    PlanningScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _HomeNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _HomeNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _HomeNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.check_box_outlined,
      Icons.bolt_outlined,
      Icons.add_circle_outline,
      Icons.person_outline,
    ];

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (i) {
          final selected = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Icon(icons[i],
                size: 26,
                color: selected ? const Color(0xFF2D1B5E) : const Color(0xFFAAAAAA)),
          );
        }),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlaceholderTab({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: const Color(0xFFAAAAAA)),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(fontSize: 18, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}
