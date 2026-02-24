import 'package:flutter/material.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  String _selectedFilter = 'All'; // 'All', 'Meetings', 'Decisions', 'Budget'
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _memoryEntries = [
    {
      'type': 'meeting',
      'title': 'Annual General Meeting 2026',
      'date': 'February 15, 2026',
      'description':
          'Discussed charity run planning, budget allocation for Q1, and new membership drive.',
      'tags': ['agm', 'planning', 'budget'],
      'participants': ['S', 'A', 'M', '+3'],
    },
    {
      'type': 'decision',
      'title': 'Charity Run Date Changed',
      'date': 'February 22, 2026',
      'description':
          'Moved Charity Run from March 12 (weekday) to March 15 (Saturday) due to availability constraints.',
      'tags': ['charity-run', 'scheduling'],
    },
    {
      'type': 'budget',
      'title': 'Water Supplies Budget Increase',
      'date': 'February 22, 2026',
      'description': 'Increased water supplies budget for Charity Run event.',
      'tags': ['charity-run', 'procurement'],
      'amount': '+RM 100',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Institutional Memory',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2A4A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete organizational history with searchable records and contextual insights',
            style: TextStyle(fontSize: 16, color: Color(0xFF7B7B93)),
          ),
          const SizedBox(height: 32),

          // Stats Row
          Row(
            children: [
              _buildStatCard(
                'Total\nMeetings',
                '3',
                Icons.calendar_today,
                const Color(0xFF6A5AE0),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Decisions\nMade',
                '2',
                Icons.description_outlined,
                const Color(0xFF6A5AE0),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Budget\nEntries',
                '2',
                Icons.attach_money,
                const Color(0xFF6A5AE0),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Active\nTasks',
                '1',
                Icons.people_outline,
                const Color(0xFF6A5AE0),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Search and Filter Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors
                        .white, // Colors.grey[100] in screenshot looks light
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.transparent,
                    ), // No visible border in screenshot
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search meetings, decisions, budgets, tasks...',
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildFilterButton(
                'All',
                'All',
                isActive: _selectedFilter == 'All',
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                'Meetings',
                'Meetings',
                icon: Icons.calendar_today,
                isActive: _selectedFilter == 'Meetings',
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                'Decisions',
                'Decisions',
                icon: Icons.description_outlined,
                isActive: _selectedFilter == 'Decisions',
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                'Budget',
                'Budget',
                icon: Icons.attach_money,
                isActive: _selectedFilter == 'Budget',
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Main Content: Timeline + Right Sidebar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Timeline
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Timeline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '8 entries found',
                      style: TextStyle(color: Color(0xFF7B7B93)),
                    ),
                    const SizedBox(height: 24),
                    ..._memoryEntries.map(
                      (entry) => _buildTimelineEntry(entry),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right: Insights & Analytics
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildQuickInsightsCard(),
                    const SizedBox(height: 24),
                    _buildMemoryAnalyticsCard(),
                  ],
                ),
              ),
            ],
          ),
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
        height: 140,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7B7B93),
                    height: 1.2,
                  ),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    String id,
    String label, {
    IconData? icon,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedFilter = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8F67E8) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? null
              : Border.all(color: Colors.grey.withAlpha(51)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineEntry(Map<String, dynamic> entry) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (entry['type']) {
      case 'meeting':
        icon = Icons.calendar_today;
        color = Colors.blue;
        bgColor = Colors.blue.withAlpha(26);
        break;
      case 'decision':
        icon = Icons.description_outlined;
        color = Colors.purple;
        bgColor = Colors.purple.withAlpha(26);
        break;
      case 'budget':
        icon = Icons.attach_money; // Or generic currency icon
        color = Colors.green;
        bgColor = Colors.green.withAlpha(26);
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
        bgColor = Colors.grey.withAlpha(26);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line & Icon
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(128), width: 1.5),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Expanded(
                child: Container(width: 2, color: Colors.grey.withAlpha(51)),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 32),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2A4A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry['type'],
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry['date'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    entry['description'],
                    style: const TextStyle(
                      color: Color(0xFF5A5A6D),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (entry['participants'] != null) ...[
                    Row(
                      children: [
                        for (var p in entry['participants'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.deepPurple[50],
                              child: Text(
                                p,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (entry['amount'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry['amount'],
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Tags
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var tag in entry['tags'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsightsCard() {
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
          Row(
            children: const [
              Icon(Icons.trending_up, color: Color(0xFF6A5AE0)),
              SizedBox(width: 8),
              Text(
                'Quick Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2A4A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Most Active Period',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            'February 2026',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2A4A),
            ),
          ),
          const Text(
            '8 recorded activities',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Top Contributors',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _buildContributorRow('Sarah', '5 meetings'),
          _buildContributorRow('Ali', '4 meetings'),
          _buildContributorRow('Emma', '3 meetings'),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Popular Tags',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag('charity-run'),
              _buildTag('planning'),
              _buildTag('budget'),
              _buildTag('marketing'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContributorRow(String name, String count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildMemoryAnalyticsCard() {
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
          Row(
            children: const [
              Icon(Icons.bar_chart, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Memory Analytics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2A4A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Storage Used', style: TextStyle(color: Colors.grey)),
              Text('48 MB', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.3,
              backgroundColor: Colors.grey[100],
              color: const Color(0xFF6A5AE0),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '102 MB available',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text('Export Options', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export as PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}
