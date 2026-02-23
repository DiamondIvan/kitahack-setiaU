import 'package:flutter/material.dart';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recording Status and Button
            Card(
              elevation: 4,
              color: _isRecording ? Colors.red[50] : Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meeting Recording',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isRecording
                                  ? 'Recording in progress...'
                                  : 'Ready to record',
                              style: TextStyle(
                                fontSize: 14,
                                color: _isRecording ? Colors.red : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _isRecording ? Colors.red : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        label: Text(
                          _isRecording ? 'Stop Recording' : 'Start Recording',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isRecording ? Colors.red : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                              'AI Pending Approval: ${_extractedTasks.length} tasks need your review',
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
                                'Assigned: ${task.assignedTo}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Due: ${task.dueDate.toString().split(' ')[0]}',
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
    );
  }
}
