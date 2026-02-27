import 'package:flutter/material.dart' hide Action;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kitahack_setiau/models/firestore_models.dart';
import 'package:kitahack_setiau/services/firestore_service.dart';
import 'package:kitahack_setiau/services/gemini_service.dart';
import 'package:kitahack_setiau/services/google_export_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class MeetingModeScreen extends StatefulWidget {
  const MeetingModeScreen({super.key});

  @override
  State<MeetingModeScreen> createState() => _MeetingModeScreenState();
}

class _MeetingModeScreenState extends State<MeetingModeScreen> {
  bool _isRecording = false;
  bool _isProcessing = false;
  String _processingStage = '';
  final SpeechToText _speechToText = SpeechToText();
  bool _speechReady = false;

  // Accumulated text from all completed recognition segments
  String _transcriptBuffer = '';
  // Current in-progress partial/final result from the active listen session
  String _currentSegment = '';

  String get _transcript => _transcriptBuffer.isEmpty
      ? _currentSegment
      : _transcriptBuffer +
            (_currentSegment.isEmpty ? '' : ' $_currentSegment');

  final List<Task> _extractedTasks = [];
  final FirestoreService _firestoreService = FirestoreService();

  String? _activeMeetingId;
  DateTime? _meetingStartTime;
  DateTime? _meetingEndTime;
  String _currentMeetingTitle = '';

  // Export state
  bool _exportingDoc = false;
  bool _exportingSheet = false;
  String? _docUrl;
  String? _sheetUrl;

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (_isRecording) {
      // Mark as no longer recording BEFORE calling stop() so that the
      // onStatus('notListening') and onError callbacks don't try to restart
      // the listener while we are intentionally stopping.
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _processingStage = 'Analyzing…';
      });

      await _speechToText.stop();

      // Commit any pending partial segment to the buffer
      if (_currentSegment.isNotEmpty) {
        _transcriptBuffer = _transcriptBuffer.isEmpty
            ? _currentSegment
            : '$_transcriptBuffer $_currentSegment';
        _currentSegment = '';
      }

      try {
        await _finalizeMeeting();
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _processingStage = '';
          });
        }
      }

      return;
    }

    final ready = await _ensureSpeechReady();
    if (!ready) return;

    final meetingId = const Uuid().v4();
    final start = DateTime.now();

    setState(() {
      _activeMeetingId = meetingId;
      _meetingStartTime = start;
      _meetingEndTime = null;
      _transcriptBuffer = '';
      _currentSegment = '';
      _extractedTasks.clear();
      _isRecording = true;
      _docUrl = null;
      _sheetUrl = null;
    });

    await _startListening();
  }

  /// Starts (or restarts) the speech-to-text listener for a single Android
  /// recognition session.  Called on first start and automatically on each
  /// Android timeout while [_isRecording] is still true.
  Future<void> _startListening() async {
    if (!mounted || !_isRecording) return;
    await _speechToText.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _currentSegment = result.recognizedWords;
          // When Android finalises a segment, commit it to the buffer so it
          // won't be lost when the listener restarts.
          if (result.finalResult && _currentSegment.isNotEmpty) {
            _transcriptBuffer = _transcriptBuffer.isEmpty
                ? _currentSegment
                : '$_transcriptBuffer $_currentSegment';
            _currentSegment = '';
          }
        });
      },
      // Give Android up to 2 minutes per recognition session before we
      // auto-restart. The OS may still cut it shorter on some devices.
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: false, // don't abort on transient errors
      ),
    );
  }

  Future<bool> _ensureSpeechReady() async {
    if (_speechReady) return true;
    final ready = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        // Android stops the recogniser automatically after its internal
        // timeout.  While the user still wants to record, restart the
        // listener immediately so they get a seamless experience.
        if (status == 'notListening' && _isRecording && !_isProcessing) {
          _startListening();
        }
      },
      onError: (error) {
        if (!mounted) return;
        // error_client means the underlying Android recognizer client is in a
        // bad state (e.g. forcibly terminated). Restarting makes it worse —
        // just ignore it entirely regardless of recording state.
        if (error.errorMsg == 'error_client') return;
        if (_isRecording && !_isProcessing) {
          // Other recoverable errors during active recording — restart listener
          _startListening();
        }
        // Any other error while stopped/processing is silently ignored
      },
    );

    if (!mounted) return false;

    if (!ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Speech recognition is unavailable or permission was denied.',
          ),
        ),
      );
      return false;
    }

    setState(() => _speechReady = true);
    return true;
  }

  Future<void> _finalizeMeeting() async {
    final meetingId = _activeMeetingId;
    if (meetingId == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You are not signed in.')));
      return;
    }

    final transcript = _transcript.trim();
    if (transcript.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No transcript captured.')));
      return;
    }

    final transcriptForAi = transcript.length > 12000
        ? transcript.substring(transcript.length - 12000)
        : transcript;

    List<Task> tasks = const [];
    try {
      final gemini = GeminiService.fromEnv();
      tasks = await gemini.extractTasksFromTranscript(
        transcriptForAi,
        meetingId,
        userId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gemini error: $e')));
      return;
    }

    if (!mounted) return;
    setState(() {
      _extractedTasks
        ..clear()
        ..addAll(tasks);
    });

    final now = DateTime.now();
    final start = _meetingStartTime ?? now;
    final meetingTitle =
        'Meeting ${start.toIso8601String().replaceFirst('T', ' ').substring(0, 16)}';

    if (mounted) {
      setState(() {
        _currentMeetingTitle = meetingTitle;
        _meetingEndTime = now;
      });
    }

    final meeting = Meeting(
      id: meetingId,
      organizationId: 'demo_org',
      title: meetingTitle,
      startTime: start,
      endTime: now,
      attendees: [userId],
      transcriptUrl: null,
      status: 'completed',
      createdAt: now,
      metadata: {'transcriptText': transcript, 'taskCount': tasks.length},
    );

    try {
      if (!mounted) return;
      setState(() {
        _processingStage = 'Saving…';
      });

      await _firestoreService.createMeetingAndTasks(meeting, tasks);

      // Generate Action documents for each task so they appear in the dashboard
      setState(() => _processingStage = 'Generating actions…');
      final actions = _buildActionsFromTasks(tasks, meetingId, userEmail);
      for (final action in actions) {
        await _firestoreService.createAction(action);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved transcript, ${tasks.length} task(s) and ${actions.length} pending action(s) to Firestore.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Firestore save error: $e')));
    }
  }

  // ---------------------------------------------------------------------------
  // Export helpers
  // ---------------------------------------------------------------------------

  Future<void> _exportToDoc() async {
    setState(() => _exportingDoc = true);
    try {
      final url = await GoogleExportService.exportTranscriptToDoc(
        meetingTitle: _currentMeetingTitle,
        transcript: _transcript,
        tasks: _extractedTasks,
        startTime: _meetingStartTime ?? DateTime.now(),
        endTime: _meetingEndTime ?? DateTime.now(),
      );
      if (!mounted) return;
      if (url != null) {
        setState(() => _docUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transcript exported to Google Docs!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => launchUrl(Uri.parse(url)),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Export failed. Make sure you are signed in with Google.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingDoc = false);
    }
  }

  Future<void> _exportToSheet() async {
    if (_extractedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tasks to export. Run the meeting first.'),
        ),
      );
      return;
    }
    setState(() => _exportingSheet = true);
    try {
      final url = await GoogleExportService.exportTasksToSheet(
        meetingTitle: _currentMeetingTitle,
        tasks: _extractedTasks,
      );
      if (!mounted) return;
      if (url != null) {
        setState(() => _sheetUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tasks exported to Google Sheets!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => launchUrl(Uri.parse(url)),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Export failed. Make sure you are signed in with Google.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingSheet = false);
    }
  }

  /// Build Action documents from extracted tasks using category-to-type mapping.
  /// These will appear in the dashboard as pending approvals.
  List<Action> _buildActionsFromTasks(
    List<Task> tasks,
    String meetingId,
    String userEmail,
  ) {
    const uuidGen = Uuid();
    final now = DateTime.now();

    // Map task category to the most appropriate Google Workspace action
    String actionTypeFor(Task t) {
      switch (t.category) {
        case 'event':
        case 'meeting':
          return 'calendar';
        case 'communication':
          return 'email';
        case 'budget':
          return 'sheets';
        case 'other':
          return 'docs';
        default:
          return 'calendar';
      }
    }

    Map<String, dynamic> defaultPayload(Task t, String actionType) {
      final String extractedTime =
          "${t.dueDate.hour.toString().padLeft(2, '0')}:${t.dueDate.minute.toString().padLeft(2, '0')}";
      final dateStr = t.dueDate.toIso8601String().split('T')[0];
      final String finalStartTime =
          (t.dueDate.hour == 0 && t.dueDate.minute == 0)
          ? '09:00'
          : extractedTime;
      switch (actionType) {
        case 'calendar':
          return {
            'eventName': t.title,
            'date': dateStr,
            'startTime': finalStartTime,
            'endTime': _calculateEndTime(finalStartTime),
            'description': t.description,
            'attendees': <String>[],
            'calendarId': userEmail,
          };
        case 'email':
          return {
            'to': t.assignedTo,
            'subject': 'Action Required: ${t.title}',
            'body':
                '${t.description}\n\nDue: $dateStr\nPriority: ${t.priority}',
            'cc': <String>[],
          };
        case 'sheets':
          return {
            'sheetName': 'Budget Tracker',
            'action': 'append',
            'values': [t.title, t.assignedTo, dateStr, t.priority, t.status],
          };
        case 'docs':
          return {
            'documentName': 'Meeting Notes: ${t.title}',
            'content':
                '# ${t.title}\n\n${t.description}\n\nAssigned to: ${t.assignedTo}\nDue: $dateStr',
            'sharing': <String>[],
          };
        default:
          return {};
      }
    }

    return tasks.map((task) {
      final actionType = actionTypeFor(task);
      return Action(
        id: uuidGen.v4(),
        taskId: task.id,
        meetingId: meetingId,
        organizationId: 'demo_org',
        actionType: actionType,
        payload: defaultPayload(task, actionType),
        status: 'pending',
        createdAt: now,
        constraints: [],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16.0 : 32.0,
            isMobile ? 16.0 : 32.0,
            isMobile ? 16.0 : 32.0,
            isMobile ? 100.0 : 32.0, // extra bottom padding for floating nav
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meeting Mode',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2A4A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Real-time AI-powered meeting intelligence',
                    style: TextStyle(fontSize: 16, color: Color(0xFF7B7B93)),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Main Layout
              if (isMobile)
                Column(
                  children: [
                    _buildAudioRecordingCard(),
                    const SizedBox(height: 24),
                    _buildLiveTranscriptCard(),
                    const SizedBox(height: 24),
                    _buildExtractedIntelligenceCard(),
                    const SizedBox(height: 24),
                    _buildMeetingStatsCard(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Main Content)
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildAudioRecordingCard(),
                          const SizedBox(height: 24),
                          _buildLiveTranscriptCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column (Sidebar)
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildExtractedIntelligenceCard(),
                          const SizedBox(height: 24),
                          _buildMeetingStatsCard(),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioRecordingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audio Recording',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2A4A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start recording to enable live transcription and AI task extraction',
            style: TextStyle(color: Color(0xFF7B7B93)),
          ),
          const SizedBox(height: 48),
          Center(
            child: SizedBox(
              height: 56,
              width: 220,
              child: ElevatedButton.icon(
                onPressed: (_isProcessing) ? null : _toggleRecording,
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                ),
                label: Text(
                  _isProcessing
                      ? (_processingStage.isEmpty
                            ? 'Processing…'
                            : _processingStage)
                      : (_isRecording ? 'Stop Meeting' : 'Start Meeting'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording
                      ? Colors.red
                      : const Color(0xFF6A5AE0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLiveTranscriptCard() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Transcript',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2A4A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Real-time speech-to-text with speaker attribution',
            style: TextStyle(color: Color(0xFF7B7B93)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withAlpha(26)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _transcript.isEmpty
                      ? (_isRecording
                            ? 'Listening... start speaking.'
                            : 'Start a meeting to generate a transcript.')
                      : _transcript,
                  style: TextStyle(color: Colors.grey[700], height: 1.4),
                ),
              ),
            ),
          ),
          if (_transcript.isNotEmpty && !_isRecording && !_isProcessing) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportingDoc ? null : _exportToDoc,
                    icon: _exportingDoc
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.description_outlined, size: 16),
                    label: Text(
                      _docUrl != null
                          ? 'Re-export to Docs'
                          : 'Export to Google Docs',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4285F4),
                      side: const BorderSide(color: Color(0xFF4285F4)),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (_docUrl != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Open in Google Docs',
                    onPressed: () => launchUrl(Uri.parse(_docUrl!)),
                    icon: const Icon(
                      Icons.open_in_new,
                      size: 20,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractedIntelligenceCard() {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF6A5AE0), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Extracted Intelligence',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2A4A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'AI-detected tasks, decisions, and actions',
            style: TextStyle(color: Color(0xFF7B7B93), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _extractedTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isProcessing
                              ? (_processingStage.isEmpty
                                    ? 'Extracting tasks…'
                                    : _processingStage)
                              : 'No tasks extracted yet',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _extractedTasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = _extractedTasks[index];
                      final due = task.dueDate
                          .toIso8601String()
                          .split('T')
                          .first;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6A5AE0).withAlpha(38),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D2A4A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${task.assignedTo} • due $due • ${task.priority}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_extractedTasks.isNotEmpty &&
              !_isRecording &&
              !_isProcessing) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportingSheet ? null : _exportToSheet,
                    icon: _exportingSheet
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.table_chart_outlined, size: 16),
                    label: Text(
                      _sheetUrl != null
                          ? 'Re-export to Sheets'
                          : 'Export to Google Sheets',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F9D58),
                      side: const BorderSide(color: Color(0xFF0F9D58)),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (_sheetUrl != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Open in Google Sheets',
                    onPressed: () => launchUrl(Uri.parse(_sheetUrl!)),
                    icon: const Icon(
                      Icons.open_in_new,
                      size: 20,
                      color: Color(0xFF0F9D58),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeetingStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meeting Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2A4A),
            ),
          ),
          const SizedBox(height: 24),
          _buildStatRow('Tasks Detected', '${_extractedTasks.length}'),
          const SizedBox(height: 16),
          _buildStatRow('Decisions Made', '0'),
          const SizedBox(height: 16),
          _buildStatRow('Actions Queued', '0'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF7B7B93))),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2A4A),
          ),
        ),
      ],
    );
  }

  String _calculateEndTime(String startTime) {
    try {
      final parts = startTime.split(':');
      int hour = int.parse(parts[0]);
      int nextHour = (hour + 1) % 24;
      return "${nextHour.toString().padLeft(2, '0')}:${parts[1]}";
    } catch (e) {
      return '10:00';
    }
  }
}
