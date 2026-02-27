import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitahack_setiau/models/firestore_models.dart';
import 'package:kitahack_setiau/services/firestore_service.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  String _selectedFilter = 'All'; // 'All', 'Meetings', 'Decisions', 'Budget'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final FirestoreService _firestoreService = FirestoreService();
  List<Meeting> _meetings = [];
  List<Task> _tasks = [];
  List<Budget> _budgets = [];
  bool _loading = true;

  StreamSubscription<List<Meeting>>? _meetingsSubscription;
  StreamSubscription<List<Task>>? _tasksSubscription;
  StreamSubscription<List<Budget>>? _budgetsSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
    _loadData();
  }

  void _loadData() {
    _meetingsSubscription = _firestoreService
        .getMeetingsForOrganization('demo_org')
        .listen(
          (meetings) {
            if (mounted) {
              setState(() {
                _meetings = meetings;
                _loading = false;
              });
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
        );

    _tasksSubscription = _firestoreService
        .getTasksForOrganization('demo_org')
        .listen((tasks) {
          if (mounted) setState(() => _tasks = tasks);
        });

    _budgetsSubscription = _firestoreService
        .getBudgetsForOrganization('demo_org')
        .listen((budgets) {
          if (mounted) setState(() => _budgets = budgets);
        });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _meetingsSubscription?.cancel();
    _tasksSubscription?.cancel();
    _budgetsSubscription?.cancel();
    super.dispose();
  }

  // ── Derived data ────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _memoryEntries {
    final List<Map<String, dynamic>> entries = [];

    if (_selectedFilter == 'All' || _selectedFilter == 'Meetings') {
      for (final m in _meetings) {
        final summary = m.metadata['summary'] as String?;
        final tags = List<String>.from(m.metadata['tags'] ?? []);
        final participants = m.attendees
            .take(3)
            .map((a) => a.isNotEmpty ? a[0].toUpperCase() : '?')
            .toList();
        if (m.attendees.length > 3) {
          participants.add('+${m.attendees.length - 3}');
        }
        entries.add({
          'type': 'meeting',
          'title': m.title,
          'date': DateFormat('MMMM d, yyyy').format(m.startTime),
          'sortDate': m.startTime,
          'description':
              summary ??
              'Meeting with ${m.attendees.length} attendee${m.attendees.length == 1 ? '' : 's'}.',
          'tags': tags,
          'participants': participants,
        });
      }
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Decisions') {
      for (final t in _tasks) {
        entries.add({
          'type': 'decision',
          'title': t.title,
          'date': DateFormat('MMMM d, yyyy').format(t.createdAt),
          'sortDate': t.createdAt,
          'description': t.description.isNotEmpty
              ? t.description
              : 'Assigned to ${t.assignedTo}.',
          'tags': [t.category, t.priority].where((s) => s.isNotEmpty).toList(),
        });
      }
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Budget') {
      for (final b in _budgets) {
        entries.add({
          'type': 'budget',
          'title': '${b.category} Budget',
          'date': DateFormat('MMMM d, yyyy').format(b.createdAt),
          'sortDate': b.createdAt,
          'description':
              'Allocated: ${b.currency} ${b.allocated.toStringAsFixed(2)}  ·  '
              'Spent: ${b.currency} ${b.spent.toStringAsFixed(2)}  ·  '
              'Remaining: ${b.currency} ${b.remaining.toStringAsFixed(2)}',
          'tags': [b.category],
          'amount': '${b.currency} ${b.spent.toStringAsFixed(2)} spent',
        });
      }
    }

    final filtered = _searchQuery.isEmpty
        ? entries
        : entries.where((e) {
            final q = _searchQuery;
            return (e['title'] as String).toLowerCase().contains(q) ||
                (e['description'] as String).toLowerCase().contains(q) ||
                (e['tags'] as List).any(
                  (tag) => tag.toString().toLowerCase().contains(q),
                );
          }).toList();

    filtered.sort(
      (a, b) =>
          (b['sortDate'] as DateTime).compareTo(a['sortDate'] as DateTime),
    );
    return filtered;
  }

  int get _totalMeetings => _meetings.length;
  int get _decisionsCount => _tasks.length;
  int get _budgetCount => _budgets.length;
  int get _activeTasksCount => _tasks
      .where((t) => t.status != 'completed' && t.status != 'rejected')
      .length;
  int get _totalEntries => _totalMeetings + _decisionsCount + _budgetCount;

  String get _mostActivePeriod {
    final allDates = [
      ..._meetings.map((m) => m.startTime),
      ..._tasks.map((t) => t.createdAt),
      ..._budgets.map((b) => b.createdAt),
    ];
    if (allDates.isEmpty) return 'N/A';
    final counts = <String, int>{};
    for (final d in allDates) {
      final key = DateFormat('MMMM yyyy').format(d);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  int get _mostActivePeriodCount {
    final allDates = [
      ..._meetings.map((m) => m.startTime),
      ..._tasks.map((t) => t.createdAt),
      ..._budgets.map((b) => b.createdAt),
    ];
    if (allDates.isEmpty) return 0;
    final counts = <String, int>{};
    for (final d in allDates) {
      final key = DateFormat('MMMM yyyy').format(d);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.values.reduce((a, b) => a >= b ? a : b);
  }

  List<MapEntry<String, int>> get _topContributors {
    final counts = <String, int>{};
    for (final m in _meetings) {
      for (final a in m.attendees) {
        counts[a] = (counts[a] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  }

  List<String> get _popularTags {
    final counts = <String, int>{};
    for (final t in _tasks) {
      if (t.category.isNotEmpty) {
        counts[t.category] = (counts[t.category] ?? 0) + 1;
      }
    }
    for (final m in _meetings) {
      final tags = m.metadata['tags'];
      if (tags is List) {
        for (final tag in tags) {
          final key = tag.toString();
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(4).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        final isSmallMobile = constraints.maxWidth < 600;

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
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                isSmallMobile
                    ? Column(
                        children: [
                          _buildStatCard(
                            'Total\nMeetings',
                            '$_totalMeetings',
                            Icons.calendar_today,
                            const Color(0xFF6A5AE0),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Decisions\nMade',
                            '$_decisionsCount',
                            Icons.description_outlined,
                            const Color(0xFF6A5AE0),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Budget\nEntries',
                            '$_budgetCount',
                            Icons.attach_money,
                            const Color(0xFF6A5AE0),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Active\nTasks',
                            '$_activeTasksCount',
                            Icons.people_outline,
                            const Color(0xFF6A5AE0),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total\nMeetings',
                              '$_totalMeetings',
                              Icons.calendar_today,
                              const Color(0xFF6A5AE0),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Decisions\nMade',
                              '$_decisionsCount',
                              Icons.description_outlined,
                              const Color(0xFF6A5AE0),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Budget\nEntries',
                              '$_budgetCount',
                              Icons.attach_money,
                              const Color(0xFF6A5AE0),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Active\nTasks',
                              '$_activeTasksCount',
                              Icons.people_outline,
                              const Color(0xFF6A5AE0),
                            ),
                          ),
                        ],
                      ),
              const SizedBox(height: 32),

              // Search and Filter Bar
              isMobile
                  ? Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search...',
                              icon: Icon(Icons.search, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
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
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    'Search meetings, decisions, budgets, tasks...',
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
              if (_loading)
                const SizedBox.shrink()
              else
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTimeline(),
                          const SizedBox(height: 32),
                          _buildQuickInsightsCard(),
                          const SizedBox(height: 24),
                          _buildMemoryAnalyticsCard(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildTimeline()),
                          const SizedBox(width: 32),
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
      },
    );
  }

  Widget _buildTimeline() {
    final entries = _memoryEntries;
    return Column(
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
        Text(
          '${entries.length} entr${entries.length == 1 ? 'y' : 'ies'} found',
          style: const TextStyle(color: Color(0xFF7B7B93)),
        ),
        const SizedBox(height: 24),
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No results for "$_searchQuery"'
                      : 'No records yet.',
                  style: const TextStyle(color: Color(0xFF7B7B93)),
                ),
              ],
            ),
          )
        else
          ...entries.map((entry) => _buildTimelineEntry(entry)),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      height: 120, // Reduced height for mobile vertical list
      padding: const EdgeInsets.all(16),
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
                    fontSize: 13,
                    color: Color(0xFF7B7B93),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2A4A),
              ),
            ),
          ),
        ],
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
                      Expanded(
                        child: Text(
                          entry['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2A4A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
    final contributors = _topContributors;
    final tags = _popularTags;
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
          Text(
            _mostActivePeriod,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2A4A),
            ),
          ),
          Text(
            '$_mostActivePeriodCount recorded activit${_mostActivePeriodCount == 1 ? 'y' : 'ies'}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Top Contributors',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (contributors.isEmpty)
            const Text(
              'No attendee data yet.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else
            ...contributors.map(
              (e) => _buildContributorRow(
                e.key,
                '${e.value} meeting${e.value == 1 ? '' : 's'}',
              ),
            ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Popular Tags',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (tags.isEmpty)
            const Text(
              'No tags yet.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map(_buildTag).toList(),
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
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
    const double maxMb = 150.0;
    // Estimate 0.5 MB per Firestore record
    final usedMb = (_totalEntries * 0.5).clamp(0.0, maxMb);
    final ratio = (usedMb / maxMb).clamp(0.0, 1.0);
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
            children: [
              const Text('Storage Used', style: TextStyle(color: Colors.grey)),
              Text(
                '${usedMb.toStringAsFixed(1)} MB',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.grey[100],
              color: const Color(0xFF6A5AE0),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(maxMb - usedMb).toStringAsFixed(1)} MB available',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
