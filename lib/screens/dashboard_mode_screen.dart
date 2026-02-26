import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:kitahack_setiau/models/firestore_models.dart';
import 'package:kitahack_setiau/services/firestore_service.dart';
import 'package:kitahack_setiau/services/gemini_service.dart';
import 'package:kitahack_setiau/services/google_calendar_service.dart';

class DashboardModeScreen extends StatefulWidget {
  const DashboardModeScreen({super.key});

  @override
  State<DashboardModeScreen> createState() => _DashboardModeScreenState();
}

class _DashboardModeScreenState extends State<DashboardModeScreen> {
  int _selectedTab = 0; // 0: Pending Approvals, 1: Recent Activity, 2: Insights

  final FirestoreService _firestoreService = FirestoreService();
  List<Action> _pendingActions = [];
  bool _loadingActions = true;
  StreamSubscription<List<Action>>? _actionsSubscription;

  int _meetingsThisMonth = 0;
  int _completedTasks = 0;
  int _totalTasks = 0;
  int _activeMembersCount = 0;
  List<Meeting> _allMeetings = [];
  List<Action> _allActions = [];
  StreamSubscription<List<Meeting>>? _meetingsSubscription;
  StreamSubscription<List<Task>>? _tasksSubscription;
  StreamSubscription<Organization?>? _orgSubscription;
  StreamSubscription<List<Action>>? _allActionsSubscription;

  // Insights
  List<Map<String, dynamic>>? _insights;
  bool _insightsLoading = false;
  String? _insightsError;

  @override
  void initState() {
    super.initState();
    _actionsSubscription = _firestoreService
        .getAllPendingActions('demo_org')
        .listen(
          (actions) {
            if (mounted) {
              setState(() {
                _pendingActions = actions;
                _loadingActions = false;
              });
            }
          },
          onError: (_) {
            if (mounted) setState(() => _loadingActions = false);
          },
        );

    _meetingsSubscription = _firestoreService
        .getMeetingsForOrganization('demo_org')
        .listen((meetings) {
          if (mounted) {
            final now = DateTime.now();
            final count = meetings
                .where(
                  (m) =>
                      m.startTime.year == now.year &&
                      m.startTime.month == now.month,
                )
                .length;
            setState(() {
              _meetingsThisMonth = count;
              _allMeetings = meetings;
            });
          }
        });

    _allActionsSubscription = _firestoreService
        .getActionsForOrganization('demo_org')
        .listen((actions) {
          if (mounted) setState(() => _allActions = actions);
        });

    _tasksSubscription = _firestoreService
        .getTasksForOrganization('demo_org')
        .listen((tasks) {
          if (mounted) {
            setState(() {
              _completedTasks = tasks
                  .where((t) => t.status == 'completed')
                  .length;
              _totalTasks = tasks.length;
            });
          }
        });

    _orgSubscription = _firestoreService
        .getOrganizationStream('demo_org')
        .listen((org) {
          if (mounted) {
            setState(() => _activeMembersCount = org?.members.length ?? 0);
          }
        });
  }

  @override
  void dispose() {
    _actionsSubscription?.cancel();
    _meetingsSubscription?.cancel();
    _tasksSubscription?.cancel();
    _orgSubscription?.cancel();
    _allActionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    if (_insightsLoading) return;
    setState(() {
      _insightsLoading = true;
      _insightsError = null;
    });
    try {
      final gemini = GeminiService.fromEnv();
      final executed = _allActions.where((a) => a.status == 'executed').length;
      final rejected = _allActions.where((a) => a.status == 'rejected').length;
      final pending = _allActions.where((a) => a.status == 'pending').length;
      final result = await gemini.generateOrgInsights({
        'meetingsThisMonth': _meetingsThisMonth,
        'totalMeetings': _allMeetings.length,
        'completedTasks': _completedTasks,
        'totalTasks': _totalTasks,
        'activeMembersCount': _activeMembersCount,
        'executedActions': executed,
        'rejectedActions': rejected,
        'pendingActions': pending,
      });
      if (mounted) {
        setState(() {
          _insights = result.isEmpty ? null : result;
          _insightsError = result.isEmpty
              ? 'No insights returned. Check your Gemini API key.'
              : null;
          _insightsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _insightsError = 'Failed to load insights: $e';
          _insightsLoading = false;
        });
      }
    }
  }

  Future<void> _approveAction(String actionId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

      // Fetch action details before approving so we can execute it
      final action = await _firestoreService.getAction(actionId);
      await _firestoreService.approveAction(actionId, uid);

      String executionResult = 'Approved';

      if (action != null && action.actionType == 'calendar') {
        final eventLink = await GoogleCalendarService.createCalendarEvent(
          action.payload,
        );
        if (eventLink != null) {
          executionResult = 'Calendar event created: $eventLink';
          await _firestoreService.executeAction(actionId, executionResult);
        } else {
          executionResult =
              'Approved but calendar event creation failed. '
              'Ensure Google Calendar is connected in Settings.';
          await _firestoreService.executeAction(actionId, executionResult);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action?.actionType == 'calendar'
                ? executionResult.startsWith('Calendar event created')
                      ? 'Meeting added to Google Calendar!'
                      : 'Approval saved, but calendar sync failed. Check Settings.'
                : 'Action approved and executed!',
          ),
          backgroundColor:
              action?.actionType == 'calendar' &&
                  !executionResult.startsWith('Calendar event created')
              ? Colors.orange
              : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approve failed: $e')));
    }
  }

  Future<void> _rejectAction(String actionId) async {
    try {
      await _firestoreService.rejectAction(actionId, 'Rejected by user');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action rejected.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reject failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmallScreen = width < 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 80.0),
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

              // Stats Cards Grid
              _buildResponsiveStats(width),
              const SizedBox(height: 32),

              // Tabs
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTab('Pending Approvals', _pendingActions.length, 0),
                      _buildTab('Recent Activity', null, 1),
                      _buildTab('Insights', null, 2),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tab Content
              if (_selectedTab == 0) _buildPendingApprovals(),
              if (_selectedTab == 1) _buildRecentActivity(),
              if (_selectedTab == 2) _buildInsights(isSmallScreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsiveStats(double width) {
    // 4 cards total
    final cards = [
      _buildStatCard(
        'Meetings This\nMonth',
        '$_meetingsThisMonth',
        Icons.calendar_today,
        Colors.blue,
      ),
      _buildStatCard(
        'Tasks\nCompleted',
        '$_completedTasks',
        Icons.check_circle_outline,
        Colors.green,
      ),
      _buildStatCard(
        'Pending\nApprovals',
        '${_pendingActions.length}',
        Icons.access_time,
        Colors.amber,
      ),
      _buildStatCard(
        'Active\nMembers',
        '$_activeMembersCount',
        Icons.people_outline,
        Colors.purple,
      ),
    ];

    if (width < 600) {
      // 1 column
      return Column(
        children: cards
            .map(
              (c) =>
                  Padding(padding: const EdgeInsets.only(bottom: 16), child: c),
            )
            .toList(),
      );
    } else if (width < 1100) {
      // 2 columns
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 16),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    } else {
      // 4 columns
      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 16),
          Expanded(child: cards[1]),
          const SizedBox(width: 16),
          Expanded(child: cards[2]),
          const SizedBox(width: 16),
          Expanded(child: cards[3]),
        ],
      );
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2A4A),
                    ),
                  ),
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
    );
  }

  Widget _buildTab(String label, int? count, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        if (index == 2 && _insights == null && !_insightsLoading) {
          _loadInsights();
        }
      },
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
    if (_loadingActions) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_pendingActions.isEmpty) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                "All clear! No pending approvals.",
                style: TextStyle(fontSize: 18, color: Color(0xFF7B7B93)),
              ),
            ],
          ),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      action.payload['eventName'] ??
                                          'Untitled Event',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D2A4A),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'From Meeting: ${action.meetingId}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF7B7B93),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[50],
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
                                    Expanded(
                                      child: Text(
                                        '${action.payload['date']} at ${action.payload['time']}',
                                        style: const TextStyle(
                                          color: Color(0xFF2D2A4A),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                    Expanded(
                                      child: Text(
                                        action.payload['venue'] ??
                                            'No venue specified',
                                        style: const TextStyle(
                                          color: Color(0xFF2D2A4A),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                          Text(
                            'Generated 2 mins ago',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _rejectAction(action.id),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE02E4C),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
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
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () => _approveAction(action.id),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1CAE4B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---- helpers for Recent Activity ----

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _actionIcon(String type) {
    switch (type) {
      case 'calendar':
        return Icons.calendar_today;
      case 'email':
        return Icons.mail_outline;
      case 'docs':
        return Icons.description_outlined;
      case 'sheets':
        return Icons.table_chart_outlined;
      default:
        return Icons.bolt;
    }
  }

  Color _actionColor(String type) {
    switch (type) {
      case 'calendar':
        return const Color(0xFF2D9CDB);
      case 'email':
        return const Color(0xFFF2994A);
      case 'docs':
        return const Color(0xFF6A5AE0);
      case 'sheets':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF6A5AE0);
    }
  }

  String _actionTitle(Action action) {
    final p = action.payload;
    final name =
        (p['eventName'] ??
                p['subject'] ??
                p['documentName'] ??
                p['sheetName'] ??
                '')
            as String;
    final label = name.isNotEmpty ? ': $name' : '';
    switch (action.status) {
      case 'executed':
        return '${_capitalize(action.actionType)} action executed$label';
      case 'approved':
        return '${_capitalize(action.actionType)} action approved$label';
      case 'rejected':
        return '${_capitalize(action.actionType)} action rejected$label';
      default:
        return '${_capitalize(action.actionType)} action$label';
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildRecentActivity() {
    // Build unified activity list from real Firestore data
    final List<Map<String, dynamic>> activities = [];

    // Non-pending actions
    for (final action in _allActions) {
      if (action.status == 'pending') continue;
      final dt = action.approvalTime ?? action.createdAt;
      activities.add({
        'title': _actionTitle(action),
        'dt': dt,
        'icon': _actionIcon(action.actionType),
        'color': action.status == 'rejected'
            ? const Color(0xFFE02E4C)
            : _actionColor(action.actionType),
      });
    }

    // Completed / ongoing meetings
    for (final meeting in _allMeetings) {
      if (meeting.status == 'draft') continue;
      activities.add({
        'title': 'Meeting ${meeting.status}: ${meeting.title}',
        'dt': meeting.startTime,
        'icon': Icons.mic,
        'color': const Color(0xFF6A5AE0),
      });
    }

    // Sort newest first, take top 15
    activities.sort(
      (a, b) => (b['dt'] as DateTime).compareTo(a['dt'] as DateTime),
    );
    final recent = activities.take(15).toList();

    return Container(
      padding: const EdgeInsets.all(24), // Reduced padding for smaller screens
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
              const Expanded(
                // Expanded title to prevent overflow
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2A4A),
                  ),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 24),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No activity yet. Approve or reject actions to see them here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF7B7B93), fontSize: 14),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              itemBuilder: (context, index) {
                final activity = recent[index];
                final isLast = index == recent.length - 1;

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
                      const SizedBox(width: 16), // Reduced gap
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
                                softWrap: true, // Allow text wrapping
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _timeAgo(activity['dt'] as DateTime),
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

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Widget _buildInsights(bool isSmallScreen) {
    // Loading state
    if (_insightsLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6A5AE0)),
              SizedBox(height: 16),
              Text(
                'Analysing your organisation data…',
                style: TextStyle(color: Color(0xFF7B7B93), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_insightsError != null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              _insightsError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7B7B93)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _insightsError = null);
                _loadInsights();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5AE0),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Not yet loaded — show generate button
    if (_insights == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5DFFF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF6A5AE0), size: 48),
            const SizedBox(height: 16),
            const Text(
              'AI-Powered Insights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2A4A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gemini will analyse your real organisation data and generate\npersonalised insights and predictions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7B7B93), height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInsights,
              icon: const Icon(Icons.bolt),
              label: const Text('Generate Insights'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5AE0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Build grid from real Gemini response
    final cards = _insights!
        .map(
          (insight) => _buildInsightCard(
            insight['title'] as String? ?? '',
            insight['subtitle'] as String? ?? '',
            insight['value'] as String? ?? '',
            insight['label'] as String? ?? '',
            insight['footer'] as String? ?? '',
            _hexToColor(insight['colorHex'] as String? ?? '#6A5AE0'),
            (insight['progress'] as num? ?? 0.5).toDouble().clamp(0.0, 1.0),
          ),
        )
        .toList();

    // Refresh button row
    final refreshRow = Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () {
          setState(() => _insights = null);
          _loadInsights();
        },
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Refresh'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF6A5AE0)),
      ),
    );

    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          refreshRow,
          const SizedBox(height: 8),
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 24),
          ],
        ],
      );
    }

    final left = cards.isNotEmpty
        ? Column(
            children: [
              cards[0],
              if (cards.length > 2) ...[const SizedBox(height: 24), cards[2]],
            ],
          )
        : const SizedBox.shrink();

    final right = cards.length > 1
        ? Column(
            children: [
              cards[1],
              if (cards.length > 3) ...[const SizedBox(height: 24), cards[3]],
            ],
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        refreshRow,
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 24),
            Expanded(child: right),
          ],
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
              color: color,
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
