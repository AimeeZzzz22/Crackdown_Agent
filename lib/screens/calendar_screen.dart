import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../services/app_state.dart';
import '../models/goal_model.dart';
import 'edit_todo_screen.dart';
import 'edit_event_screen.dart';
import 'new_todo_screen.dart';
import 'new_event_screen.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class CalendarTask {
  final String id;
  final String title;
  final String tag;
  final String? time;
  final DateTime? date;
  final DateTime createdAt;
  final Color? goalColor;
  final bool isEvent;
  bool completed;

  CalendarTask({
    String? id,
    required this.title,
    required this.tag,
    this.time,
    this.date,
    DateTime? createdAt,
    this.goalColor,
    this.isEvent = false,
    this.completed = false,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  int? get timeValue {
    if (time == null || time!.isEmpty) return null;
    final s = time!.toUpperCase();
    final m = RegExp(r'(\d+)(AM|PM)?').firstMatch(s);
    if (m == null) return null;
    int h = int.tryParse(m.group(1) ?? '0') ?? 0;
    final p = m.group(2);
    if (p == 'PM' && h != 12) h += 12;
    if (p == 'AM' && h == 12) h = 0;
    return h;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _selectedDay;
  bool _completedExpanded = true;
  final _searchController = TextEditingController();

  // Sample / demo tasks (always visible for demo purposes)
  final List<CalendarTask> _sampleTasks = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDay = now;
    AppState.instance.addListener(_onStateChange);

    // Seed a few demo tasks on today for first-time visitors
    final today = DateTime(now.year, now.month, now.day);
    _sampleTasks.addAll([
      CalendarTask(
        id: 'demo_1',
        title: 'Review your goals',
        tag: '# Daily check-in',
        time: '9AM',
        date: today,
        createdAt: today,
        goalColor: const Color(0xFF9E9E9E),
        isEvent: false,
      ),
      CalendarTask(
        id: 'demo_2',
        title: 'Plan your week',
        tag: '# Productivity',
        time: null,
        date: today,
        createdAt: today,
        goalColor: const Color(0xFF64B5F6),
        isEvent: false,
      ),
    ]);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onStateChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onStateChange() => setState(() {});

  // Convert AppState todos + events into CalendarTask list
  List<CalendarTask> get _appStateTasks {
    final tasks = <CalendarTask>[];
    final appState = AppState.instance;

    // Map goal name → color for coloring tasks
    final goalColors = <String, Color>{};
    for (final g in appState.goals) {
      goalColors[g.name] = g.color;
    }

    // Todos
    for (final todo in appState.todos) {
      tasks.add(CalendarTask(
        id: 'todo_${todo.id}',
        title: todo.title,
        tag: todo.tag.isNotEmpty ? '# ${todo.tag}' : todo.repeat != 'Never' ? '# ${todo.repeat}' : '',
        time: null,
        date: todo.date,
        createdAt: todo.date ?? DateTime.now(),
        goalColor: todo.goalName != null ? goalColors[todo.goalName] : null,
        isEvent: false,
        completed: todo.completed,
      ));
    }

    // Events
    for (final event in appState.events) {
      tasks.add(CalendarTask(
        id: 'event_${event.id}',
        title: event.title,
        tag: event.tag.isNotEmpty
            ? '# ${event.tag}'
            : event.location.isNotEmpty
                ? '# ${event.location}'
                : '',
        time: event.startTime.isNotEmpty ? event.startTime : null,
        date: event.date,
        createdAt: event.date ?? DateTime.now(),
        goalColor: null,
        isEvent: true,
        completed: false,
      ));
    }

    return tasks;
  }

  List<CalendarTask> get _allTasks => [..._sampleTasks, ..._appStateTasks];

  // Dots on calendar — any day that has tasks
  Set<int> get _daysWithTasks {
    final days = <int>{};
    for (final task in _allTasks) {
      if (task.date != null &&
          task.date!.month == _currentMonth.month &&
          task.date!.year == _currentMonth.year) {
        days.add(task.date!.day);
      }
    }
    return days;
  }

  List<CalendarTask> get _filteredTasks {
    final query = _searchController.text.trim().toLowerCase();
    return _allTasks.where((t) {
      final matchesDate = t.date == null ||
          (t.date!.year == _selectedDay.year &&
              t.date!.month == _selectedDay.month &&
              t.date!.day == _selectedDay.day);
      final matchesSearch = query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.tag.toLowerCase().contains(query);
      return matchesDate && matchesSearch;
    }).toList();
  }

  List<CalendarTask> _sorted(List<CalendarTask> tasks) {
    final out = List<CalendarTask>.from(tasks);
    out.sort((a, b) {
      if (a.timeValue == null && b.timeValue == null) {
        return a.createdAt.compareTo(b.createdAt);
      }
      if (a.timeValue == null) return -1;
      if (b.timeValue == null) return 1;
      return a.timeValue!.compareTo(b.timeValue!);
    });
    return out;
  }

  List<CalendarTask> get _incompleteTasks =>
      _sorted(_filteredTasks.where((t) => !t.completed).toList());
  List<CalendarTask> get _completedTasks =>
      _sorted(_filteredTasks.where((t) => t.completed).toList());

  void _prevMonth() => setState(() {
        _currentMonth =
            DateTime(_currentMonth.year, _currentMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _currentMonth =
            DateTime(_currentMonth.year, _currentMonth.month + 1);
      });

  void _updateTask(String taskId, Map<String, dynamic> data) {
    setState(() {
      final idx = _sampleTasks.indexWhere((t) => t.id == taskId);
      if (idx != -1) {
        final old = _sampleTasks[idx];
        _sampleTasks[idx] = CalendarTask(
          id: taskId,
          title: data['title'] ?? old.title,
          tag: data['tag'] != null ? '#${data['tag']}' : old.tag,
          time: data['startTime'] ?? data['time'] ?? old.time,
          date: data['date'] ?? old.date,
          goalColor: old.goalColor,
          isEvent: old.isEvent,
          completed: old.completed,
        );
      }
      // AppState tasks: update the underlying AppState item
      if (taskId.startsWith('todo_')) {
        final id = taskId.replaceFirst('todo_', '');
        final t = AppState.instance.todos.firstWhere(
          (t) => t.id == id,
          orElse: () => TodoItem(id: '', title: ''),
        );
        if (t.id.isNotEmpty) {
          t.title = data['title'] ?? t.title;
          t.date = data['date'] ?? t.date;
          t.tag = data['tag'] ?? t.tag;
          AppState.instance.notifyListeners();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCalendarBg,
      floatingActionButton: _AddButton(selectedDay: _selectedDay),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.epilogue(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search tasks & events',
                    hintStyle:
                        GoogleFonts.epilogue(fontSize: 13, color: kCalendarGray),
                    prefixIcon:
                        Icon(Icons.search, size: 18, color: kCalendarGray),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),

            // Month header with arrows — swipeable
            GestureDetector(
              onHorizontalDragEnd: (d) {
                if (d.primaryVelocity == null) return;
                if (d.primaryVelocity! < -200) _nextMonth();
                if (d.primaryVelocity! > 200) _prevMonth();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _prevMonth,
                      child: const Icon(Icons.chevron_left, size: 28),
                    ),
                    Expanded(
                      child: Text(
                        '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                        style: GoogleFonts.merriweather(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _nextMonth,
                      child: const Icon(Icons.chevron_right, size: 28),
                    ),
                  ],
                ),
              ),
            ),

            // Calendar grid — swipe left/right to change month
            GestureDetector(
              onHorizontalDragEnd: (d) {
                if (d.primaryVelocity == null) return;
                if (d.primaryVelocity! < -200) _nextMonth();
                if (d.primaryVelocity! > 200) _prevMonth();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _CalendarGrid(
                  month: _currentMonth,
                  selectedDay: _selectedDay,
                  daysWithTasks: _daysWithTasks,
                  onDaySelected: (d) => setState(() => _selectedDay = d),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Task list — scrollable
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEEEE),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    // Completed section
                    if (_completedTasks.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => setState(
                            () => _completedExpanded = !_completedExpanded),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _completedExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text('Completed (${_completedTasks.length})',
                                  style: GoogleFonts.epilogue(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      if (_completedExpanded)
                        ..._completedTasks.map((t) => _TaskRow(
                              task: t,
                              onToggle: () => setState(() {
                                t.completed = !t.completed;
                                // sync to AppState if it's an AppState todo
                                if (t.id.startsWith('todo_')) {
                                  final id = t.id.replaceFirst('todo_', '');
                                  AppState.instance.toggleTodo(id);
                                }
                              }),
                              onUpdate: _updateTask,
                            )),
                    ],

                    // Active tasks
                    if (_incompleteTasks.isEmpty && _completedTasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No tasks for this day.\nTap + to add one!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.epilogue(
                                fontSize: 14, color: Colors.black45),
                          ),
                        ),
                      ),

                    ..._incompleteTasks.map((t) => _TaskRow(
                          task: t,
                          onToggle: () => setState(() {
                            t.completed = !t.completed;
                            if (t.id.startsWith('todo_')) {
                              final id = t.id.replaceFirst('todo_', '');
                              AppState.instance.toggleTodo(id);
                            }
                          }),
                          onUpdate: _updateTask,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        '',
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m];
}

// ── Add FAB ───────────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final DateTime selectedDay;
  const _AddButton({required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF2D1B5E),
      child: const Icon(Icons.add, color: Colors.white),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.check_box_outlined),
                  title: Text('Add To-Do',
                      style: GoogleFonts.epilogue(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NewTodoScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text('Add Event',
                      style: GoogleFonts.epilogue(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NewEventScreen()));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Calendar Grid ─────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final Set<int> daysWithTasks;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarGrid({
    required this.month,
    required this.selectedDay,
    required this.daysWithTasks,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final today = DateTime.now();
    final totalCells = startWeekday + daysInMonth;
    final gridCount = totalCells + (7 - totalCells % 7) % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
              .map((d) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(d,
                          style: GoogleFonts.epilogue(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.1,
          ),
          itemCount: gridCount,
          itemBuilder: (_, i) {
            if (i < startWeekday) {
              final prevDays = DateTime(month.year, month.month, 0).day;
              return _DayCell(
                day: prevDays - startWeekday + i + 1,
                isCurrentMonth: false,
                isToday: false,
                isSelected: false,
                hasDot: false,
                onTap: () {},
              );
            }
            final day = i - startWeekday + 1;
            if (day > daysInMonth) {
              return _DayCell(
                day: day - daysInMonth,
                isCurrentMonth: false,
                isToday: false,
                isSelected: false,
                hasDot: false,
                onTap: () {},
              );
            }
            final date = DateTime(month.year, month.month, day);
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isSelected = date.year == selectedDay.year &&
                date.month == selectedDay.month &&
                date.day == selectedDay.day;
            return _DayCell(
              day: day,
              isCurrentMonth: true,
              isToday: isToday,
              isSelected: isSelected,
              hasDot: daysWithTasks.contains(day),
              onTap: () => onDaySelected(date),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isCurrentMonth, isToday, isSelected, hasDot;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.hasDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCurrentMonth ? onTap : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFF2D1B5E)
                  : isToday
                      ? const Color(0xFF2D1B5E).withValues(alpha: 0.15)
                      : Colors.transparent,
            ),
            child: Center(
              child: Text(
                '$day',
                style: GoogleFonts.epilogue(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : isCurrentMonth
                          ? Colors.black
                          : kCalendarGray,
                ),
              ),
            ),
          ),
          if (hasDot && isCurrentMonth)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : const Color(0xFF2D1B5E),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Task Row ──────────────────────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  final CalendarTask task;
  final VoidCallback onToggle;
  final Function(String, Map<String, dynamic>) onUpdate;

  const _TaskRow(
      {required this.task, required this.onToggle, required this.onUpdate});

  Future<void> _openEdit(BuildContext context) async {
    Map<String, dynamic>? result;
    if (task.isEvent) {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditEventScreen(
            initialTitle: task.title,
            initialDate: task.date,
            initialStartTime: task.time ?? '',
            initialEndTime: '',
            initialLocation: '',
            initialNotification: true,
            initialRepeat: 'Never',
            initialTag: task.tag.replaceAll('#', '').trim(),
          ),
        ),
      );
    } else {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditTodoScreen(
            initialTitle: task.title,
            initialDate: task.date,
            initialNotes: '',
            initialRepeat: 'Never',
            initialTag: task.tag.replaceAll('#', '').trim(),
          ),
        ),
      );
    }
    if (result != null) onUpdate(task.id, result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                task.time ?? '',
                style:
                    GoogleFonts.epilogue(fontSize: 11, color: kCalendarGray),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => _openEdit(context),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: onToggle,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 2, right: 8),
                                child: Icon(
                                  task.completed
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: task.completed
                                      ? const Color(0xFF2D1B5E)
                                      : kCalendarGray,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: GoogleFonts.merriweather(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                      decoration: task.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  if (task.tag.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(task.tag,
                                        style: GoogleFonts.epilogue(
                                            fontSize: 11,
                                            color: kCalendarTaskText)),
                                  ],
                                  if (task.isEvent)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2D1B5E)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text('Event',
                                            style: GoogleFonts.epilogue(
                                                fontSize: 10,
                                                color:
                                                    const Color(0xFF2D1B5E))),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (task.goalColor != null)
                      Container(
                        width: 6,
                        height: 56,
                        decoration: BoxDecoration(
                          color: task.goalColor,
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
