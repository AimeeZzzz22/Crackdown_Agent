import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_state.dart';

class AgentResponse {
  final String reply;
  final bool success;
  AgentResponse({required this.reply, this.success = true});
}

class AgentService {
  AgentService._();
  static final AgentService instance = AgentService._();

  // ── Set this to your Vercel deployment URL after deploying ─────────────────
  // e.g. 'https://crackdown-agent-xyz.vercel.app/api/chat'
  static const _proxyUrl = 'https://crackdown-agent.vercel.app/api/chat';

  static const _model = 'claude-sonnet-4-6';

  Future<AgentResponse> process(String userMessage) async {
    final state = AppState.instance;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final goalNames = state.goals.map((g) => g.name).join(', ');

    final systemPrompt = '''
You are a friendly AI assistant built into the Crackdown productivity app.
The user will tell you what they want to do. Parse their request and respond ONLY with a valid JSON object — no extra text, no markdown fences.

Today's date: $dateStr
User's existing goals: $goalNames

Response format:
{
  "action": "add_todo" | "add_event" | "add_goal" | "query" | "unknown",
  "data": { ...fields },
  "reply": "A warm, short confirmation message (1-2 sentences)"
}

For add_todo:
  data = { "title": string, "date": "YYYY-MM-DD" or null, "goalName": string or null, "tag": string, "repeat": "Never"|"Daily"|"Weekly" }

For add_event:
  data = { "title": string, "date": "YYYY-MM-DD", "startTime": "H:MM AM/PM", "endTime": "H:MM AM/PM", "location": string }

For add_goal:
  data = { "name": string, "colorHex": "#RRGGBB", "reasons": [string] }

For query:
  data = { "answer": string }

For unknown:
  data = {}

Parse relative dates like "tomorrow", "next Monday" relative to today ($dateStr).
''';

    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'max_tokens': 512,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage}
          ],
        }),
      );

      if (response.statusCode != 200) {
        return AgentResponse(
          reply: 'Sorry, I had trouble connecting. Please try again.',
          success: false,
        );
      }

      final body = jsonDecode(response.body);
      final text = (body['content'] as List).first['text'] as String;

      // Strip any accidental markdown fences
      final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
      final Map<String, dynamic> parsed = jsonDecode(clean);

      final action = parsed['action'] as String;
      final data = (parsed['data'] as Map<String, dynamic>?) ?? {};
      final reply = parsed['reply'] as String? ?? 'Done!';

      _executeAction(action, data, state);

      return AgentResponse(reply: reply);
    } catch (e) {
      return AgentResponse(
        reply: 'Something went wrong. Please try again.',
        success: false,
      );
    }
  }

  void _executeAction(
      String action, Map<String, dynamic> data, AppState state) {
    switch (action) {
      case 'add_todo':
        final item = state.createTodo(
          title: data['title'] as String? ?? 'New Todo',
          date: _parseDate(data['date'] as String?),
          tag: data['tag'] as String? ?? '',
          repeat: data['repeat'] as String? ?? 'Never',
          goalName: data['goalName'] as String?,
        );
        state.addTodo(item);

      case 'add_event':
        final item = state.createEvent(
          title: data['title'] as String? ?? 'New Event',
          date: _parseDate(data['date'] as String?),
          startTime: data['startTime'] as String? ?? '',
          endTime: data['endTime'] as String? ?? '',
          location: data['location'] as String? ?? '',
        );
        state.addEvent(item);

      case 'add_goal':
        final colorHex = data['colorHex'] as String? ?? '#9E9E9E';
        final color = _hexToColor(colorHex);
        final reasons = (data['reasons'] as List?)
                ?.map((r) => r.toString())
                .toList() ??
            [];
        state.addGoal(state.createGoal(
          name: data['name'] as String? ?? 'New Goal',
          color: color,
          reasons: reasons,
        ));

      default:
        break;
    }
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return const Color(0xFF9E9E9E);
  }
}
