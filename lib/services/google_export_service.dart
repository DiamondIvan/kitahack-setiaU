import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:kitahack_setiau/models/firestore_models.dart';

/// Handles exporting meeting data to Google Docs and Google Sheets.
class GoogleExportService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/documents',
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  // ---------------------------------------------------------------------------
  // Auth helpers
  // ---------------------------------------------------------------------------

  static Future<String?> _getAccessToken() async {
    try {
      var account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      return auth.accessToken;
    } catch (e) {
      debugPrint('GoogleExportService: sign-in error – $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  static Future<bool> isSignedIn() async {
    final account = await _googleSignIn.signInSilently();
    return account != null;
  }

  // ---------------------------------------------------------------------------
  // Google Docs – transcript export
  // ---------------------------------------------------------------------------

  /// Creates a new Google Doc with the full meeting intelligence report.
  /// Returns the URL of the created document, or null on failure.
  static Future<String?> exportTranscriptToDoc({
    required String meetingTitle,
    required String transcript,
    required List<Task> tasks,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final token = await _getAccessToken();
    if (token == null) {
      debugPrint('GoogleExportService: no access token for Docs');
      return null;
    }

    // ── Step 1: create an empty document ─────────────────────────────────────
    final createRes = await http.post(
      Uri.parse('https://docs.googleapis.com/v1/documents'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': 'Meeting Report: $meetingTitle'}),
    );

    if (createRes.statusCode != 200) {
      debugPrint(
        'GoogleExportService: Docs create error ${createRes.statusCode}: ${createRes.body}',
      );
      return null;
    }

    final docId =
        (jsonDecode(createRes.body) as Map<String, dynamic>)['documentId']
            as String;

    // ── Step 2: build the document content via batchUpdate ───────────────────
    final content = _buildDocContent(
      meetingTitle: meetingTitle,
      transcript: transcript,
      tasks: tasks,
      startTime: startTime,
      endTime: endTime,
    );

    // Insert text at index 1 (right after the document start)
    final batchRes = await http.post(
      Uri.parse('https://docs.googleapis.com/v1/documents/$docId:batchUpdate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'requests': [
          {
            'insertText': {
              'location': {'index': 1},
              'text': content,
            },
          },
        ],
      }),
    );

    if (batchRes.statusCode != 200) {
      debugPrint(
        'GoogleExportService: Docs batchUpdate error ${batchRes.statusCode}: ${batchRes.body}',
      );
      // Return the doc URL anyway – it was created, just without content
    }

    final url = 'https://docs.google.com/document/d/$docId/edit';
    debugPrint('GoogleExportService: Doc created – $url');
    return url;
  }

  static String _buildDocContent({
    required String meetingTitle,
    required String transcript,
    required List<Task> tasks,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final buf = StringBuffer();

    final dateStr =
        '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
    final startStr = _fmtTime(startTime);
    final endStr = _fmtTime(endTime);
    final duration = endTime.difference(startTime);
    final durationStr =
        '${duration.inMinutes} min ${duration.inSeconds % 60} sec';

    buf.writeln('MEETING INTELLIGENCE REPORT');
    buf.writeln('='.padRight(60, '='));
    buf.writeln('Title    : $meetingTitle');
    buf.writeln('Date     : $dateStr');
    buf.writeln('Time     : $startStr – $endStr  ($durationStr)');
    buf.writeln('Tasks    : ${tasks.length} action item(s) extracted');
    buf.writeln();

    // ── Transcript ──
    buf.writeln('LIVE TRANSCRIPT');
    buf.writeln('-'.padRight(60, '-'));
    buf.writeln(transcript.isEmpty ? '(no transcript captured)' : transcript);
    buf.writeln();

    // ── Extracted tasks ──
    if (tasks.isNotEmpty) {
      buf.writeln('EXTRACTED ACTION ITEMS');
      buf.writeln('-'.padRight(60, '-'));
      for (var i = 0; i < tasks.length; i++) {
        final t = tasks[i];
        final due = t.dueDate.toIso8601String().split('T').first;
        buf.writeln('${i + 1}. [${t.priority.toUpperCase()}] ${t.title}');
        buf.writeln('   Assigned  : ${t.assignedTo}');
        buf.writeln('   Due       : $due');
        buf.writeln('   Category  : ${t.category}');
        if (t.description.isNotEmpty) {
          buf.writeln('   Notes     : ${t.description}');
        }
        buf.writeln();
      }
    }

    buf.writeln('─'.padRight(60, '─'));
    buf.writeln('Generated by SetiaU  ·  ${DateTime.now().toIso8601String()}');

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Google Sheets – tasks export
  // ---------------------------------------------------------------------------

  /// Creates a new Google Spreadsheet with extracted tasks.
  /// Returns the URL of the created spreadsheet, or null on failure.
  static Future<String?> exportTasksToSheet({
    required String meetingTitle,
    required List<Task> tasks,
  }) async {
    final token = await _getAccessToken();
    if (token == null) {
      debugPrint('GoogleExportService: no access token for Sheets');
      return null;
    }

    final dateStr = DateTime.now().toIso8601String().split('T').first;

    // ── Step 1: create the spreadsheet with headers + data ─────────────────
    final rows = <List<dynamic>>[
      // header row
      [
        '#',
        'Task Title',
        'Assigned To',
        'Due Date',
        'Priority',
        'Category',
        'Status',
        'Description',
      ],
      // data rows
      for (var i = 0; i < tasks.length; i++)
        [
          i + 1,
          tasks[i].title,
          tasks[i].assignedTo,
          tasks[i].dueDate.toIso8601String().split('T').first,
          tasks[i].priority,
          tasks[i].category,
          tasks[i].status,
          tasks[i].description,
        ],
    ];

    final createRes = await http.post(
      Uri.parse('https://sheets.googleapis.com/v4/spreadsheets'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'properties': {'title': 'Meeting Tasks – $meetingTitle ($dateStr)'},
        'sheets': [
          {
            'properties': {'title': 'Action Items'},
            'data': [
              {
                'startRow': 0,
                'startColumn': 0,
                'rowData': rows
                    .map(
                      (row) => {
                        'values': row
                            .map(
                              (cell) => {
                                'userEnteredValue': cell is int
                                    ? {'numberValue': cell}
                                    : {'stringValue': cell.toString()},
                              },
                            )
                            .toList(),
                      },
                    )
                    .toList(),
              },
            ],
          },
          // Summary sheet
          {
            'properties': {'title': 'Summary'},
            'data': [
              {
                'startRow': 0,
                'startColumn': 0,
                'rowData': [
                  {
                    'values': [
                      {
                        'userEnteredValue': {'stringValue': 'Meeting'},
                      },
                      {
                        'userEnteredValue': {'stringValue': meetingTitle},
                      },
                    ],
                  },
                  {
                    'values': [
                      {
                        'userEnteredValue': {'stringValue': 'Export Date'},
                      },
                      {
                        'userEnteredValue': {'stringValue': dateStr},
                      },
                    ],
                  },
                  {
                    'values': [
                      {
                        'userEnteredValue': {'stringValue': 'Total Tasks'},
                      },
                      {
                        'userEnteredValue': {'numberValue': tasks.length},
                      },
                    ],
                  },
                  {
                    'values': [
                      {
                        'userEnteredValue': {'stringValue': 'High Priority'},
                      },
                      {
                        'userEnteredValue': {
                          'numberValue': tasks
                              .where((t) => t.priority == 'high')
                              .length,
                        },
                      },
                    ],
                  },
                  {
                    'values': [
                      {
                        'userEnteredValue': {'stringValue': 'Medium Priority'},
                      },
                      {
                        'userEnteredValue': {
                          'numberValue': tasks
                              .where((t) => t.priority == 'medium')
                              .length,
                        },
                      },
                    ],
                  },
                  {
                    'values': [
                      {
                        'userEnteredValue': {'stringValue': 'Low Priority'},
                      },
                      {
                        'userEnteredValue': {
                          'numberValue': tasks
                              .where((t) => t.priority == 'low')
                              .length,
                        },
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      }),
    );

    if (createRes.statusCode != 200) {
      debugPrint(
        'GoogleExportService: Sheets create error ${createRes.statusCode}: ${createRes.body}',
      );
      return null;
    }

    final spreadsheetId =
        (jsonDecode(createRes.body) as Map<String, dynamic>)['spreadsheetId']
            as String;

    final url = 'https://docs.google.com/spreadsheets/d/$spreadsheetId/edit';
    debugPrint('GoogleExportService: Sheet created – $url');
    return url;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _fmtTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
