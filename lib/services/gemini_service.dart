import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:kitahack_setiau/models/firestore_models.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

class GeminiService {
  late final GenerativeModel _model;
  static const Uuid _uuid = Uuid();

  GeminiService({required String apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// Factory constructor that loads API key from environment variables
  factory GeminiService.fromEnv() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY not found in .env file. '
        'Please add GEMINI_API_KEY=your_api_key to your .env file',
      );
    }
    return GeminiService(apiKey: apiKey);
  }

  /// Process meeting transcript and extract tasks
  /// Returns a list of Task objects extracted by Gemini
  Future<List<Task>> extractTasksFromTranscript(
    String transcript,
    String meetingId,
    String userId,
  ) async {
    final prompt =
        '''
You are SetiaU, an agentic secretary for student organizations and NGOs.

Analyze the following meeting transcript and extract all actionable tasks, decisions, and action items.

Return at most 10 tasks.

For each task, provide:
1. Clear title (max 10 words)
2. Detailed description
3. Assigned person (if mentioned)
4. Priority level (high/medium/low based on urgency/importance)
5. Estimated due date (if mentioned, otherwise suggest based on urgency)
6. Category (meeting/event/budget/communication/other)

Meeting Transcript:
---
$transcript
---

Return response as a JSON array with this structure:
[
  {
    "title": "Task title",
    "description": "Full description",
    "assignedTo": "Person name or 'Unassigned'",
    "priority": "high|medium|low",
    "dueDate": "YYYY-MM-DD",
    "category": "meeting|event|budget|communication|other"
  }
]

IMPORTANT: Return ONLY valid JSON array, no additional text.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model
          .generateContent(content)
          .timeout(const Duration(seconds: 25));
      final responseText = response.text ?? '[]';

      // Parse JSON response
      final tasks = _parseTasksFromJson(responseText, meetingId, userId);
      return tasks;
    } catch (e) {
      debugPrint('Error extracting tasks: $e');
      return [];
    }
  }

  /// Detect constraints and validate proposed actions
  /// Returns list of constraint messages
  Future<List<String>> detectConstraints(
    Task task,
    List<String> organizationMembers,
    List<Budget> budgets,
  ) async {
    final prompt =
        '''
You are SetiaU, an agentic secretary. Analyze the following task and detect any potential conflicts or constraints:

Task:
- Title: ${task.title}
- Assigned to: ${task.assignedTo}
- Due Date: ${task.dueDate.toString().split(' ')[0]}
- Category: ${task.category}
- Priority: ${task.priority}

Organization Members: ${organizationMembers.join(', ')}
Available Budgets:
${budgets.map((b) => '- ${b.category}: ${b.currency} ${b.spent}/${b.allocated} (${b.percentageUsed.toStringAsFixed(0)}% used)').join('\n')}

Detect:
1. Member availability issues
2. Budget constraints
3. Date conflicts (weekends, public holidays)
4. Duplicate task assignments
5. Timeline feasibility

Return response as a JSON array of constraint messages:
["Constraint 1", "Constraint 2", ...]

Return ONLY valid JSON array, no additional text.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model
          .generateContent(content)
          .timeout(const Duration(seconds: 25));
      final responseText = response.text ?? '[]';

      // Parse constraint messages
      return _parseConstraintsFromJson(responseText);
    } catch (e) {
      debugPrint('Error detecting constraints: $e');
      return [];
    }
  }

  /// Generate AI-proposed alternative solution
  Future<String> proposeAlternativeSolution(
    Task task,
    List<String> constraints,
  ) async {
    final prompt =
        '''
You are SetiaU, an agentic secretary helping solve organizational challenges.

Task: ${task.title}
Current Issues: ${constraints.join('\n')}

Propose a practical alternative that resolves these constraints while achieving the task goal.
Be specific with dates, people, and actionable steps.

Return ONLY the proposed solution as plain text (no JSON, no markdown).
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model
          .generateContent(content)
          .timeout(const Duration(seconds: 25));
      return response.text ?? 'Unable to generate alternative solution';
    } catch (e) {
      debugPrint('Error proposing alternative: $e');
      return 'Unable to generate alternative solution';
    }
  }

  /// Generate action payloads for Google Workspace APIs
  /// Returns structured data for calendar, email, sheets, docs operations
  Future<Map<String, dynamic>> generateActionPayload(
    Task task,
    String actionType,
  ) async {
    final prompt =
        '''
You are SetiaU generating structured API payloads for Google Workspace automation.

Task: ${task.title}
Action Type: $actionType
Description: ${task.description}
Assigned To: ${task.assignedTo}
Due Date: ${task.dueDate.toString().split(' ')[0]}

Generate appropriate payload for $actionType in JSON format:

${_getPayloadTemplate(actionType)}

Return ONLY valid JSON object, no additional text.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model
          .generateContent(content)
          .timeout(const Duration(seconds: 25));
      final responseText = response.text ?? '{}';

      return _parsePayloadFromJson(responseText);
    } catch (e) {
      debugPrint('Error generating action payload: $e');
      return {};
    }
  }

  // Helper Methods
  List<Task> _parseTasksFromJson(
    String jsonText,
    String meetingId,
    String userId,
  ) {
    try {
      final cleaned = _stripMarkdownCodeFences(jsonText);
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) return [];

      final now = DateTime.now();

      return decoded
          .whereType<Map>()
          .map((raw) => raw.cast<String, dynamic>())
          .map((map) {
            final title = (map['title'] ?? '').toString().trim();
            final description = (map['description'] ?? '').toString().trim();
            final assignedTo = (map['assignedTo'] ?? 'Unassigned')
                .toString()
                .trim();
            final priority = (map['priority'] ?? 'medium')
                .toString()
                .toLowerCase()
                .trim();
            final category = (map['category'] ?? 'other')
                .toString()
                .toLowerCase()
                .trim();

            final dueDateRaw = (map['dueDate'] ?? '').toString().trim();
            final parsedDueDate = DateTime.tryParse(dueDateRaw);
            final dueDate = parsedDueDate ?? now.add(const Duration(days: 7));

            return Task(
              id: _uuid.v4(),
              meetingId: meetingId,
              title: title.isEmpty ? 'Untitled task' : title,
              description: description.isEmpty ? 'No description' : description,
              assignedTo: assignedTo.isEmpty ? 'Unassigned' : assignedTo,
              dueDate: dueDate,
              priority: _normalizePriority(priority),
              category: _normalizeCategory(category),
              createdAt: now,
              createdBy: userId,
            );
          })
          .toList();
    } catch (e) {
      debugPrint('Error parsing tasks JSON: $e');
      return [];
    }
  }

  List<String> _parseConstraintsFromJson(String jsonText) {
    try {
      final cleaned = _stripMarkdownCodeFences(jsonText);
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) return [];
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Error parsing constraints JSON: $e');
      return [];
    }
  }

  Map<String, dynamic> _parsePayloadFromJson(String jsonText) {
    try {
      final cleaned = _stripMarkdownCodeFences(jsonText);
      final decoded = jsonDecode(cleaned);
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return {};
    } catch (e) {
      debugPrint('Error parsing payload JSON: $e');
      return {};
    }
  }

  static String _stripMarkdownCodeFences(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'```\s*$'), '');
    }
    return cleaned.trim();
  }

  static String _normalizePriority(String value) {
    switch (value) {
      case 'high':
      case 'medium':
      case 'low':
        return value;
      default:
        return 'medium';
    }
  }

  static String _normalizeCategory(String value) {
    switch (value) {
      case 'meeting':
      case 'budget':
      case 'event':
      case 'communication':
      case 'other':
        return value;
      default:
        return 'other';
    }
  }

  String _getPayloadTemplate(String actionType) {
    switch (actionType) {
      case 'calendar':
        return '''
{
  "eventName": "string",
  "date": "YYYY-MM-DD",
  "startTime": "HH:MM",
  "endTime": "HH:MM",
  "description": "string",
  "attendees": ["email1", "email2"]
}
        ''';
      case 'email':
        return '''
{
  "to": "recipient@example.com",
  "subject": "string",
  "body": "string (markdown allowed)",
  "cc": ["optional@emails.com"]
}
        ''';
      case 'sheets':
        return '''
{
  "sheetName": "string",
  "action": "append|update|create",
  "data": {
    "row": integer,
    "values": ["value1", "value2"]
  }
}
        ''';
      case 'docs':
        return '''
{
  "documentName": "string",
  "content": "string (markdown)",
  "sharing": ["email1@example.com"]
}
        ''';
      default:
        return '{}';
    }
  }
}
