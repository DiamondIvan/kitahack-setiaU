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
              _buildStatCard(
                'Meetings This\nMonth',
                '12',
                Icons.calendar_today,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Tasks\nCompleted',
                '48',
                Icons.check_circle_outline,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Pending\nApprovals',
                '3',
                Icons.access_time,
                Colors.amber,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Active\nMembers',
                '24',
                Icons.people_outline,
                Colors.purple,
              ),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(38),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7B7B93),
                      height: 1.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2A4A),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '+5%', // Placeholder for trend
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
                ),
              ],
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2D2A4A)
                    : const Color(0xFF9090A7),
                fontSize: 14,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE02E4C)
                      : const Color(0xFFE02E4C).withAlpha(179),
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
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              "All clear! No pending approvals.",
              style: TextStyle(fontSize: 18, color: Color(0xFF7B7B93)),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _pendingActions.map((action) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withAlpha(26),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 8, color: Colors.amber[400]),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
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
                                      color: Colors.amber[50],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.calendar_today,
                                      color: Colors.amber[700],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        action.payload['eventName'] ??
                                            'Untitled Event',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D2A4A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'From Meeting: ${action.meetingId}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF7B7B93),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.amber[50], // Soft amber background
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  action.actionType.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_filled,
                                      size: 16,
                                      color: Color(0xFF7B7B93),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${action.payload['date']} at ${action.payload['time']}',
                                      style: const TextStyle(
                                        color: Color(0xFF2D2A4A),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Color(0xFF7B7B93),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      action.payload['venue'] ??
                                          'No venue specified',
                                      style: const TextStyle(
                                        color: Color(0xFF2D2A4A),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  action.payload['details'] ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFF7B7B93),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Generated 2 mins ago',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _rejectAction(action.id),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFE02E4C),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFE02E4C),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => _approveAction(action.id),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1CAE4B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
                ],
              ),
            ),
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
        'color': const Color(0xFF6A5AE0),
      },
      {
        'title': 'Calendar event created: Monthly Review',
        'time': '3 hours ago',
        'icon': Icons.calendar_today,
        'color': const Color(0xFF2D9CDB),
      },
      {
        'title': 'Budget sheet updated: Q1 Expenses',
        'time': '5 hours ago',
        'icon': Icons.attach_money,
        'color': const Color(0xFF27AE60),
      },
      {
        'title': 'New member registration form created',
        'time': 'Yesterday',
        'icon': Icons.person_add,
        'color': const Color(0xFFF2994A),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2A4A),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final isLast = index == activities.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (activity['color'] as Color).withAlpha(
                                128,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (activity['color'] as Color).withAlpha(
                                  51,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            activity['icon'] as IconData,
                            color: activity['color'] as Color,
                            size: 16,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: Colors.grey[200],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF2D2A4A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity['time'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7B7B93),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
            color: Colors.black.withAlpha(13),
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
          Text(subtitle, style: const TextStyle(color: Color(0xFF7B7B93))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF7B7B93))),
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
