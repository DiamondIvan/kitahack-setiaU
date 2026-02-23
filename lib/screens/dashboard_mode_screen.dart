import 'package:flutter/material.dart' hide Action;
import 'package:kitahack_setiau/models/firestore_models.dart';

class DashboardModeScreen extends StatefulWidget {
  const DashboardModeScreen({super.key});

  @override
  State<DashboardModeScreen> createState() => _DashboardModeScreenState();
}

class _DashboardModeScreenState extends State<DashboardModeScreen> {
  // Mock data
  final List<Action> _pendingActions = [
    Action(
      id: 'action_001',
      taskId: 'task_001',
      meetingId: 'meeting_001',
      actionType: 'calendar',
      payload: {
        'eventName': 'Charity Run - Updated',
        'date': '2026-03-13',
        'time': '09:00 AM',
        'attendees': ['Ali', 'Sarah', 'John'],
      },
      status: 'pending',
      createdAt: DateTime.now(),
      constraints: ['Date conflict: Multiple members unavailable on March 12'],
    ),
    Action(
      id: 'action_002',
      taskId: 'task_002',
      meetingId: 'meeting_001',
      actionType: 'email',
      payload: {
        'recipient': 'team@example.com',
        'subject': 'Charity Run - Saturday March 13',
        'body': 'Meeting summary and action items...',
      },
      status: 'pending',
      createdAt: DateTime.now(),
      constraints: [],
    ),
    Action(
      id: 'action_003',
      taskId: 'task_003',
      meetingId: 'meeting_001',
      actionType: 'sheets',
      payload: {
        'sheetName': 'Event Budget',
        'category': 'Water Supplies',
        'amount': 100.00,
        'currency': 'MYR',
      },
      status: 'pending',
      createdAt: DateTime.now(),
      constraints: [
        'Budget Warning: This purchase would use 85% of water budget (RM500 total allocated)',
      ],
    ),
  ];

  final List<Task> _recentTasks = [
    Task(
      id: 'task_001',
      meetingId: 'meeting_001',
      title: 'Plan Charity Run Event',
      description: 'Organize charity run on March 13 (Saturday)',
      assignedTo: 'Ali',
      dueDate: DateTime(2026, 3, 13),
      priority: 'high',
      status: 'pending',
      category: 'event',
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
    Task(
      id: 'task_002',
      meetingId: 'meeting_001',
      title: 'Design Event Poster',
      description: 'Create promotional poster for event',
      assignedTo: 'Sarah',
      dueDate: DateTime(2026, 3, 6),
      priority: 'high',
      status: 'pending',
      category: 'event',
      createdAt: DateTime.now(),
      createdBy: 'system',
    ),
  ];

  void _approveAction(String actionId) {
    setState(() {
      final action = _pendingActions.firstWhere((a) => a.id == actionId);
      final index = _pendingActions.indexOf(action);
      _pendingActions.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Action approved and executed!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectAction(String actionId) {
    setState(() {
      final action = _pendingActions.firstWhere((a) => a.id == actionId);
      final index = _pendingActions.indexOf(action);
      _pendingActions.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Action rejected.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Memory Analytics & Timeline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Timeline', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2A4A))),
                    const SizedBox(height: 16),
                    ..._recentTasks.map((task) => Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: Icon(Icons.assignment, color: Color(0xFF6A5AE0)),
                        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(task.description),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Due: ${task.dueDate.toString().split(' ')[0]}', style: TextStyle(fontSize: 12, color: Color(0xFF7B7B93))),
                            Chip(label: Text(task.priority), backgroundColor: task.priority == 'high' ? Color(0xFFE06767) : Color(0xFFFFE066)),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Quick Insights & Memory Analytics
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quick Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2A4A))),
                            const SizedBox(height: 12),
                            Text('Most Active Period', style: TextStyle(fontSize: 14, color: Color(0xFF7B7B93))),
                            Text('February 2026', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text('Top Contributors', style: TextStyle(fontSize: 14, color: Color(0xFF7B7B93))),
                            Wrap(
                              spacing: 8,
                              children: [
                                Chip(label: Text('Sarah'), backgroundColor: Color(0xFF6A5AE0)),
                                Chip(label: Text('Ali'), backgroundColor: Color(0xFF8F67E8)),
                                Chip(label: Text('Emma'), backgroundColor: Color(0xFF6A5AE0)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Popular Tags', style: TextStyle(fontSize: 14, color: Color(0xFF7B7B93))),
                            Wrap(
                              spacing: 8,
                              children: [
                                Chip(label: Text('charity-run'), backgroundColor: Color(0xFFE06767)),
                                Chip(label: Text('planning'), backgroundColor: Color(0xFF6A5AE0)),
                                Chip(label: Text('budget'), backgroundColor: Color(0xFF8F67E8)),
                                Chip(label: Text('marketing'), backgroundColor: Color(0xFFFFE066)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Memory Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2A4A))),
                            const SizedBox(height: 12),
                            Text('Storage Used', style: TextStyle(fontSize: 14, color: Color(0xFF7B7B93))),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: 0.48,
                                    minHeight: 8,
                                    backgroundColor: Color(0xFFF5F6FA),
                                    color: Color(0xFF6A5AE0),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('48 MB', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('102 MB available', style: TextStyle(fontSize: 12, color: Color(0xFF7B7B93))),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.download, color: Colors.white),
                              label: Text('Export as PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6A5AE0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getActionTitle(Action action) {
    switch (action.actionType) {
      case 'calendar':
        return 'Create Calendar Event: ${action.payload['eventName'] ?? 'Unknown'}';
      case 'email':
        return 'Send Email: ${action.payload['subject'] ?? 'Unknown'}';
      case 'sheets':
        return 'Update Budget: ${action.payload['sheetName'] ?? 'Unknown'}';
      case 'docs':
        return 'Create Document: ${action.payload['docName'] ?? 'Unknown'}';
      default:
        return 'Execute Action';
    }
  }

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'calendar':
        return Colors.blue;
      case 'email':
        return Colors.orange;
      case 'sheets':
        return Colors.green;
      case 'docs':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
