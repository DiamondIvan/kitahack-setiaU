import 'package:flutter/material.dart';
import '_stat_box.dart';
import 'package:kitahack_setiau/models/firestore_models.dart';

class MeetingModeScreen extends StatefulWidget {
  const MeetingModeScreen({super.key});

  @override
  State<MeetingModeScreen> createState() => _MeetingModeScreenState();
}

class _MeetingModeScreenState extends State<MeetingModeScreen> {
  bool _isRecording = false;
  final String _transcriptText = '';
  List<Task> _extractedTasks = [];

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (!_isRecording) {
        // When recording stops, simulate AI processing
        _simulateAIProcessing();
      }
    });
  }

  void _startRecording() {
     _toggleRecording();
  }

  void _stopRecording() {
     _toggleRecording();
  }    

  void _simulateAIProcessing() {
    // Simulate Gemini extracting tasks from the meeting
    setState(() {
      _extractedTasks = [
        Task(
          id: '1',
          meetingId: 'meeting_001',
          title: 'Plan Charity Run Event',
          description: 'Organize charity run on March 12',
          assignedTo: 'Ali',
          dueDate: DateTime.now().add(const Duration(days: 14)),
          priority: 'high',
          category: 'event',
          createdAt: DateTime.now(),
          createdBy: 'system',
        ),
        Task(
          id: '2',
          meetingId: 'meeting_001',
          title: 'Design Event Poster',
          description: 'Create promotional poster for event',
          assignedTo: 'Sarah',
          dueDate: DateTime.now().add(const Duration(days: 7)),
          priority: 'high',
          category: 'event',
          createdAt: DateTime.now(),
          createdBy: 'system',
        ),
        Task(
          id: '3',
          meetingId: 'meeting_001',
          title: 'Manage Water Supplies',
          description: 'Source and manage water for charity run',
          assignedTo: 'Ali',
          dueDate: DateTime.now().add(const Duration(days: 14)),
          priority: 'medium',
          category: 'event',
          createdAt: DateTime.now(),
          createdBy: 'system',
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: const Color(0xFFF5F6FA),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Audio Recording', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D2A4A))),
                                const SizedBox(height: 8),
                                Text('Start recording to enable live transcription and AI task extraction', style: TextStyle(fontSize: 14, color: Color(0xFF7B7B93))),
                                const SizedBox(height: 24),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _isRecording ? _stopRecording : _startRecording,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isRecording ? const Color(0xFFE06767) : const Color(0xFF6A5AE0),
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text(_isRecording ? 'Stop Meeting' : 'Start Meeting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(Icons.assignment, size: 32, color: Color(0xFF6A5AE0)),
                                const SizedBox(height: 8),
                                Text('No tasks extracted yet', style: TextStyle(fontSize: 16, color: Color(0xFF7B7B93))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Live Transcript', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2A4A))),
                                const SizedBox(height: 16),
                                Center(
                                  child: Icon(Icons.mic, size: 40, color: Color(0xFF6A5AE0)),
                                ),
                                const SizedBox(height: 8),
                                Text('Real-time speech-to-text with speaker attribution', style: TextStyle(fontSize: 14, color: Color(0xFF7B7B93))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Meeting Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2A4A))),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    StatBox(label: 'Tasks Detected', value: '0'),
                                    StatBox(label: 'Decisions Made', value: '0'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    StatBox(label: 'Actions Queued', value: '0'),
                                    StatBox(label: 'AI Interventions', value: '0'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Transcript Section
                  if (_transcriptText.isNotEmpty || _isRecording)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Transcript',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: Text(
                            _isRecording
                                ? 'Listening to meeting discussion...'
                                : _transcriptText,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  // Extracted Tasks Section
                  if (_extractedTasks.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Extracted Tasks (AI-Generated)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          color: Colors.amber[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.amber[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'AI Pending Approval:  tasks need your review',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _extractedTasks.length,
                          itemBuilder: (context, index) {
                            final task = _extractedTasks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.assignment,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                title: Text(task.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Assigned: ',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Due: ',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(task.priority),
                                  backgroundColor: task.priority == 'high'
                                      ? Colors.red[100]
                                      : Colors.yellow[100],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Tasks approved and saved!'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Approve & Save'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _extractedTasks.clear();
                                  });
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Discard'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
