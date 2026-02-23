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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_pendingActions.length}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Text(
                          'Pending Actions',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_recentTasks.length}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const Text(
                          'Open Tasks',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Pending Actions Section
          const Text(
            'Pending Approvals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_pendingActions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green[100],
                    ),
                    const SizedBox(height: 12),
                    const Text('All actions approved!'),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingActions.length,
              itemBuilder: (context, index) {
                final action = _pendingActions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getActionTitle(action),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(action.actionType),
                          backgroundColor: _getActionColor(action.actionType),
                          labelStyle: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (action.constraints.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Constraints Detected:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...action.constraints.map((constraint) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                        left: 12.0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.warning,
                                            size: 16,
                                            color: Colors.red[700],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              constraint,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            const Text(
                              'Action Details:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...action.payload.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        '${entry.key}:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value.toString(),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _approveAction(action.id),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _rejectAction(action.id),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          // Recent Tasks Section
          const Text(
            'Recent Tasks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentTasks.length,
            itemBuilder: (context, index) {
              final task = _recentTasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.assignment, color: Colors.purple[700]),
                  ),
                  title: Text(task.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Assigned to: ${task.assignedTo}',
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
