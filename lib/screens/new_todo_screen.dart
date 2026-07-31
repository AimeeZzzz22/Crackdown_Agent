import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/todo_shared_widgets.dart';
import '../services/app_state.dart';
import '../utils/validation.dart';
import 'new_event_screen.dart';

class NewTodoScreen extends StatefulWidget {
  const NewTodoScreen({super.key});

  @override
  State<NewTodoScreen> createState() => _NewTodoScreenState();
}

class _NewTodoScreenState extends State<NewTodoScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();

  DateTime? _selectedDate;
  bool _datePickerOpen = false;
  DateTime _calendarMonth = DateTime(2022, 11);

  String _repeat = 'Never';
  bool _repeatExpanded = false;
  final List<String> _repeatOptions = ['Never', 'Everyday', 'Every week', 'Every month'];

  String? _selectedGoal;
  bool _goalExpanded = false;
  List<String> get _goals =>
      AppState.instance.goals.map((g) => g.name).toList();

  bool _tagFocused = false;
  final List<String> _suggestedTags = ['School', 'fun', 'work', 'life'];
  final List<String> _userTags = [];

  int _navIndex = 0;
  bool _isTodoMode = true;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  TextStyle get _labelStyle => GoogleFonts.epilogue(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: kTodoTitle,
      );

  InputDecoration _fieldDecoration({String? hint, Widget? prefix}) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.epilogue(color: kTodoPlaceholder, fontSize: 14),
        prefixIcon: prefix,
        filled: true,
        fillColor: kTodoFieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kTodoBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kTodoTitle.withValues(alpha: 0.4)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kTodoBgTop, kTodoBgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.chevron_left, color: kTodoTitle, size: 28),
                    ),
                    const Spacer(),
                    TodoEventToggle(
                      isTodo: _isTodoMode,
                      onChanged: (v) {
                        if (!v) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const NewEventScreen()),
                          );
                        } else {
                          setState(() => _isTodoMode = v);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Title
              Center(
                child: Text(
                  'New To do',
                  style: GoogleFonts.merriweather(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kTodoTitle,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      RichText(
                        text: TextSpan(
                          style: _labelStyle,
                          children: [
                            const TextSpan(text: 'Title'),
                            TextSpan(text: '*', style: TextStyle(color: kTodoRequired)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        style: GoogleFonts.epilogue(color: kTodoTitle, fontSize: 14),
                        decoration: _fieldDecoration(),
                      ),
                      const SizedBox(height: 14),

                      // Date field
                      Text('Date', style: _labelStyle),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => setState(() => _datePickerOpen = !_datePickerOpen),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: kTodoFieldBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kTodoBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_outlined, color: kTodoIcon, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : '16/7/2023',
                                style: GoogleFonts.epilogue(color: kTodoPlaceholder, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Inline calendar
                      if (_datePickerOpen) ...[
                        const SizedBox(height: 4),
                        InlineCalendar(
                          month: _calendarMonth,
                          selected: _selectedDate,
                          onMonthChanged: (m) => setState(() => _calendarMonth = m),
                          onDateSelected: (d) => setState(() {
                            _selectedDate = d;
                            _datePickerOpen = false;
                          }),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Notes
                      Text('Notes', style: _labelStyle),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        style: GoogleFonts.epilogue(color: kTodoTitle, fontSize: 14),
                        decoration: _fieldDecoration(),
                      ),
                      const SizedBox(height: 14),

                      // Repeat
                      Text('Repeat', style: _labelStyle),
                      const SizedBox(height: 6),
                      ExpandableField(
                        icon: Icons.repeat,
                        label: _repeat,
                        expanded: _repeatExpanded,
                        onToggle: () => setState(() => _repeatExpanded = !_repeatExpanded),
                        children: _repeatOptions
                            .where((o) => o != _repeat)
                            .map((o) => ExpandableOption(
                                  icon: Icons.repeat,
                                  label: o,
                                  onTap: () => setState(() {
                                    _repeat = o;
                                    _repeatExpanded = false;
                                  }),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 14),

                      // Tag
                      Text('Tag', style: _labelStyle),
                      const SizedBox(height: 6),
                      Focus(
                        onFocusChange: (f) => setState(() => _tagFocused = f),
                        child: TextField(
                          controller: _tagController,
                          style: GoogleFonts.epilogue(color: kTodoTitle, fontSize: 14),
                          decoration: _fieldDecoration(
                            hint: 'Tag',
                            prefix: Padding(
                              padding: const EdgeInsets.only(left: 12, right: 8),
                              child: Icon(Icons.tag, color: kTodoIcon, size: 18),
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setState(() {
                                _userTags.add(val.trim());
                                _tagController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      if (_tagFocused) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: kTodoFieldBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kTodoBorder),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [..._suggestedTags, ..._userTags].map((tag) {
                              return GestureDetector(
                                onTap: () => setState(() => _tagController.text = tag),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: kTodoBgTop.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: kTodoBorder),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: GoogleFonts.epilogue(fontSize: 12, color: kTodoTitle),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Works towards this goal
                      Text('Works towards this goal', style: _labelStyle),
                      const SizedBox(height: 6),
                      ExpandableField(
                        icon: Icons.filter_alt_outlined,
                        label: _selectedGoal ?? 'Select a goal',
                        expanded: _goalExpanded,
                        onToggle: () => setState(() => _goalExpanded = !_goalExpanded),
                        labelColor: _selectedGoal == null ? kTodoPlaceholder : kTodoTitle,
                        children: _goals
                            .map((g) => ExpandableOption(
                                  icon: Icons.filter_alt_outlined,
                                  label: g,
                                  onTap: () => setState(() {
                                    _selectedGoal = g;
                                    _goalExpanded = false;
                                  }),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 28),

                      // Add button
                      Center(
                        child: SizedBox(
                          width: 160,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              final title = _titleController.text.trim();
                              if (title.isEmpty) {
                                showValidationDialog(context, ['Title is required']);
                                return;
                              }
                              final todo = AppState.instance.createTodo(
                                title: title,
                                date: _selectedDate,
                                notes: _notesController.text.trim(),
                                repeat: _repeat,
                                tag: _tagController.text.trim(),
                                goalName: _selectedGoal,
                              );
                              AppState.instance.addTodo(todo);
                              showSuccessSnackBar(context, 'To-do added!');
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kTodoFieldBg,
                              foregroundColor: kTodoTitle,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              'Add',
                              style: GoogleFonts.merriweather(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: kTodoTitle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

