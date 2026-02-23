import 'package:flutter/material.dart' hide Action;
import 'package:kitahack_setiau/models/firestore_models.dart';

class DashboardModeScreen extends StatefulWidget {
  const DashboardModeScreen({super.key});

  @override
  State<DashboardModeScreen> createState() => _DashboardModeScreenState();
}

class _DashboardModeScreenState extends State<DashboardModeScreen> {
  int _selectedTab = 0; // 0: Pending Approvals, 1: Recent Activity, 2: Insights

  // Mock data for Pending Approvals
  final List<Action> _pendingActions = [
    Action(
      id: 'action_001',
      taskId: 'task_001',
      meetingId: 'meeting_001',
      actionType: 'calendar',
      payload: {
        'eventName': 'Create Charity Run Event',
        'date': '2026-03-15',
        'time': '08:00 AM',
        'venue': 'Central Park',
        'details': 'Saturday, March 15, 2026 at 8:00 AM - Venue: Central Park',
        'timestamp': '2 minutes ago',
      },
      status: 'pending',
      createdAt: DateTime.now(),
      constraints: [],
    ),
  ];

  void _approveAction(String actionId) {
    setState(() {
      _pendingActions.removeWhere((a) => a.id == actionId);
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
      _pendingActions.removeWhere((a) => a.id == actionId);
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
          // Title
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2A4A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Welcome back! Here\'s what\'s happening with your organization.',
            style: TextStyle(fontSize: 16, color: Color(0xFF7B7B93)),
          ),
          const SizedBox(height: 24),

          // Welcome Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5DFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFF6A5AE0)),
                    SizedBox(width: 8),
                    Text(
                      'Welcome to SetiaU!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A5AE0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is a demonstration of SetiaU\'s agentic AI secretary capabilities. Try the Meeting Mode to see live AI task extraction, or explore Institutional Memory to view organizational history.',
                  style: TextStyle(color: Color(0xFF6A5AE0), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Row(
            children: [
              _buildStatCard('Meetings This\nMonth', '12', Icons.calendar_today, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard('Tasks\nCompleted', '48', Icons.check_circle_outline, Colors.green),
              const SizedBox(width: 16),
              _buildStatCard('Pending\nApprovals', '3', Icons.access_time, Colors.amber),
              const SizedBox(width: 16),
              _buildStatCard('Active\nMembers', '24', Icons.people_outline, Colors.purple),
            ],
          ),
          const SizedBox(height: 32),

          // Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTab('Pending Approvals', 3, 0),
                _buildTab('Recent Activity', null, 1),
                _buildTab('Insights', null, 2),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tab Content
          if (_selectedTab == 0) _buildPendingApprovals(),
          if (_selectedTab == 1) _buildRecentActivity(),
          if (_selectedTab == 2) _buildInsights(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 160, // Increased height to prevent overflow
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Flexible(
                   child: Text(
                     title,
                     style: const TextStyle(
                       fontSize: 14,
                       color: Color(0xFF7B7B93),
                       height: 1.2,
                     ),
                   ),
                 ),
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: color.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Icon(icon, color: color, size: 24),
                 ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2A4A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int? count, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF2D2A4A) : const Color(0xFF7B7B93),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE02E4C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovals() {
    if (_pendingActions.isEmpty) {
        return const Center(child: Text("No actions pending approval."));
    }
    return Column(
      children: _pendingActions.map((action) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: Colors.amber[400]!, width: 6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[50], // Use light amber background
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.calendar_today, color: Colors.amber[700]), // Proper icon color
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.payload['eventName'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2A4A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action.payload['details'],
                            style: const TextStyle(color: Color(0xFF7B7B93)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber[100]!),
                    ),
                    child: const Text(
                      'calendar',
                      style: TextStyle(
                        color: Colors.amber, // Ensure text is visible
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '2 minutes ago',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _approveAction(action.id),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve & Execute'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CAE4B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _rejectAction(action.id),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE02E4C),
                      side: const BorderSide(color: Color(0xFFE02E4C)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {
        'title': 'Meeting minutes generated for AGM Planning',
        'time': '1 hour ago',
        'icon': Icons.description,
        'color': Colors.green,
      },
      {
        'title': 'Calendar event created: Monthly Review',
        'time': '3 hours ago',
        'icon': Icons.calendar_today,
        'color': Colors.green,
      },
      {
        'title': 'Budget sheet updated: Q1 Expenses',
        'time': '5 hours ago',
        'icon': Icons.attach_money,
        'color': Colors.green,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2A4A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your organization\'s latest actions and executions',
            style: TextStyle(color: Color(0xFF7B7B93)),
          ),
          const SizedBox(height: 24),
          ...activities.map((activity) => Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (activity['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: activity['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D2A4A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['time'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7B7B93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildInsightCard(
                'Meeting Efficiency',
                'Average time saved per meeting',
                '-65%',
                'Admin Tasks',
                'You\'re saving an average of 45 minutes per meeting',
                Colors.green,
                0.65,
              ),
              const SizedBox(height: 24),
              _buildInsightCard(
                'Budget Tracking',
                'Current quarter spending',
                'RM 4,250',
                'Q1 2026',
                'RM 1,750 remaining of RM 6,000 budget',
                Colors.purple,
                0.70,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              _buildInsightCard(
                'Task Completion Rate',
                'Tasks completed on time',
                '89%',
                'This Month',
                '43 out of 48 tasks completed within deadline',
                Colors.blue,
                0.89,
              ),
              const SizedBox(height: 24),
              _buildInsightCard(
                'Member Engagement',
                'Active participation rate',
                '24/30',
                'Active Members',
                '80% of members attended last meeting',
                Colors.blue[900]!,
                0.80,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String title,
    String subtitle,
    String value,
    String label,
    String footer,
    Color color,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2A4A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF7B7B93)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF7B7B93)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: Colors.black, // From screenshot design
            ),
          ),
          const SizedBox(height: 12),
          Text(
            footer,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7B7B93)),
          ),
        ],
      ),
    );
  }
}
