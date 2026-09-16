import 'package:flutter/material.dart';
import '../models/goal_model.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class TodoItem {
  final String id;
  String title;
  DateTime? date;
  String notes;
  String repeat;
  String tag;
  String? goalName;
  bool completed;

  TodoItem({
    required this.id,
    required this.title,
    this.date,
    this.notes = '',
    this.repeat = 'Never',
    this.tag = '',
    this.goalName,
    this.completed = false,
  });
}

class EventItem {
  final String id;
  String title;
  DateTime? date;
  String startTime;
  String endTime;
  String location;
  bool notification;
  String repeat;
  String tag;

  EventItem({
    required this.id,
    required this.title,
    this.date,
    this.startTime = '',
    this.endTime = '',
    this.location = '',
    this.notification = true,
    this.repeat = 'Never',
    this.tag = '',
  });
}

// ── App State singleton ───────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  AppState._() {
    _seedSampleData();
  }
  static final AppState instance = AppState._();

  final List<TodoItem> todos = [];
  final List<EventItem> events = [];
  final List<GoalModel> goals = List.from(sampleGoals);

  int _idCounter = 0;
  String _nextId() => 'item_${++_idCounter}';

  void _seedSampleData() {
    final now = DateTime.now();
    // Helper to make a date relative to today
    DateTime d(int offsetDays) {
      final t = now.add(Duration(days: offsetDays));
      return DateTime(t.year, t.month, t.day);
    }

    // ── "Get An Internship" todos (gray) ─────────────────────────────────────
    todos.addAll([
      TodoItem(id: _nextId(), title: 'Revise the Resume',
          date: d(-3), tag: 'Career', goalName: 'Get An Internship'),
      TodoItem(id: _nextId(), title: 'Engineer Career Fair',
          date: d(2), tag: 'Career', goalName: 'Get An Internship'),
      TodoItem(id: _nextId(), title: 'Interview Training',
          date: d(5), tag: 'Career', goalName: 'Get An Internship'),
    ]);

    // ── "Get An Internship" events ────────────────────────────────────────────
    events.addAll([
      EventItem(id: _nextId(), title: 'Engineer Career Fair',
          date: d(2), startTime: '10:00 AM', endTime: '4:00 PM',
          location: 'Campus Rec Center', tag: 'Career'),
      EventItem(id: _nextId(), title: 'Mock Interview Session',
          date: d(6), startTime: '2:00 PM', endTime: '3:30 PM',
          location: 'Career Center Room 202', tag: 'Career'),
    ]);

    // ── "Get Fit" todos (yellow) ──────────────────────────────────────────────
    todos.addAll([
      TodoItem(id: _nextId(), title: 'Go to the gym',
          date: d(0), tag: 'Health', repeat: 'Daily', goalName: 'Get Fit'),
      TodoItem(id: _nextId(), title: 'Meal prep',
          date: d(1), tag: 'Health', goalName: 'Get Fit'),
      TodoItem(id: _nextId(), title: 'Go to the gym',
          date: d(2), tag: 'Health', repeat: 'Daily', goalName: 'Get Fit'),
    ]);

    // ── "Get Fit" events ──────────────────────────────────────────────────────
    events.addAll([
      EventItem(id: _nextId(), title: 'Morning Run',
          date: d(0), startTime: '7:00 AM', endTime: '8:00 AM',
          location: 'Campus Trail', tag: 'Health'),
      EventItem(id: _nextId(), title: 'Gym Session',
          date: d(3), startTime: '6:00 PM', endTime: '7:30 PM',
          location: 'Campus Gym', tag: 'Health'),
    ]);

    // ── "Get A+ on Econ" todos (red) ─────────────────────────────────────────
    todos.addAll([
      TodoItem(id: _nextId(), title: 'Finish the Econ HW',
          date: d(1), tag: 'School', goalName: 'Get A+ on Econ'),
      TodoItem(id: _nextId(), title: 'Midterm 3 --Econ',
          date: d(7), tag: 'School', goalName: 'Get A+ on Econ'),
      TodoItem(id: _nextId(), title: 'Office hours',
          date: d(4), tag: 'School', goalName: 'Get A+ on Econ'),
    ]);

    // ── "Get A+ on Econ" events ───────────────────────────────────────────────
    events.addAll([
      EventItem(id: _nextId(), title: 'Econ Midterm 3',
          date: d(7), startTime: '10:00 AM', endTime: '12:00 PM',
          location: 'Hall 101', tag: 'School'),
      EventItem(id: _nextId(), title: 'Professor Office Hours',
          date: d(4), startTime: '3:00 PM', endTime: '4:00 PM',
          location: 'Econ Dept. Rm 305', tag: 'School'),
    ]);
  }

  // ── Todos ──────────────────────────────────────────────────────────────────
  void addTodo(TodoItem item) {
    todos.add(item);
    notifyListeners();
  }

  void toggleTodo(String id) {
    final idx = todos.indexWhere((t) => t.id == id);
    if (idx != -1) {
      todos[idx].completed = !todos[idx].completed;
      notifyListeners();
    }
  }

  TodoItem createTodo({
    required String title,
    DateTime? date,
    String notes = '',
    String repeat = 'Never',
    String tag = '',
    String? goalName,
  }) {
    return TodoItem(
      id: _nextId(),
      title: title,
      date: date,
      notes: notes,
      repeat: repeat,
      tag: tag,
      goalName: goalName,
    );
  }

  // ── Events ─────────────────────────────────────────────────────────────────
  void addEvent(EventItem item) {
    events.add(item);
    notifyListeners();
  }

  EventItem createEvent({
    required String title,
    DateTime? date,
    String startTime = '',
    String endTime = '',
    String location = '',
    bool notification = true,
    String repeat = 'Never',
    String tag = '',
  }) {
    return EventItem(
      id: _nextId(),
      title: title,
      date: date,
      startTime: startTime,
      endTime: endTime,
      location: location,
      notification: notification,
      repeat: repeat,
      tag: tag,
    );
  }

  // ── Goals ──────────────────────────────────────────────────────────────────
  void addGoal(GoalModel goal) {
    goals.add(goal);
    notifyListeners();
  }

  GoalModel createGoal({
    required String name,
    required Color color,
    List<String> reasons = const [],
  }) {
    return GoalModel(
      name: name,
      color: color,
      timePercent: 0.0,
      taskPercent: 0.0,
      endDate: '',
      streakDays: 0,
      reasons: reasons,
      tasks: [],
      inspirationTexts: [],
      chartData: [0.0],
    );
  }

  /// Get all todos that belong to a specific goal name
  List<TodoItem> todosForGoal(String goalName) =>
      todos.where((t) => t.goalName == goalName).toList();

  /// Get todos for a specific date
  List<TodoItem> todosForDate(DateTime date) => todos
      .where((t) =>
          t.date != null &&
          t.date!.year == date.year &&
          t.date!.month == date.month &&
          t.date!.day == date.day)
      .toList();

  /// Get events for a specific date
  List<EventItem> eventsForDate(DateTime date) => events
      .where((e) =>
          e.date != null &&
          e.date!.year == date.year &&
          e.date!.month == date.month &&
          e.date!.day == date.day)
      .toList();
}
