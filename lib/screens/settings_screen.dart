import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kitahack_setiau/models/firestore_models.dart';
import 'package:kitahack_setiau/services/firestore_service.dart';
import 'package:kitahack_setiau/services/google_calendar_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTab = 'Profile';

  final _firestoreService = FirestoreService();
  Organization? _org;
  bool _orgLoading = true;
  StreamSubscription<Organization?>? _orgSub;

  @override
  void initState() {
    super.initState();
    _orgSub = _firestoreService
        .getOrganizationStream('demo_org')
        .listen(
          (org) {
            if (mounted) {
              setState(() {
                _org = org;
                _orgLoading = false;
              });
            }
          },
          onError: (_) {
            if (mounted) setState(() => _orgLoading = false);
          },
        );
  }

  @override
  void dispose() {
    _orgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 40.0;

        return Container(
          color: const Color(0xFFF5F6FA),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              padding,
              padding,
              padding,
              isMobile ? 100 : 40,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your SetiaU configuration and preferences',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    // Tabs
                    SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Row(
                          children: [
                            _SettingsTab(
                              label: 'Profile',
                              icon: Icons.person_outline,
                              isSelected: _selectedTab == 'Profile',
                              compact: isMobile,
                              onTap: () =>
                                  setState(() => _selectedTab = 'Profile'),
                            ),
                            const SizedBox(width: 8),
                            _SettingsTab(
                              label: 'Notifications',
                              icon: Icons.notifications_outlined,
                              isSelected: _selectedTab == 'Notifications',
                              compact: isMobile,
                              onTap: () => setState(
                                () => _selectedTab = 'Notifications',
                              ),
                            ),
                            const SizedBox(width: 8),
                            _SettingsTab(
                              label: 'Integrations',
                              icon: Icons.bolt_outlined,
                              isSelected: _selectedTab == 'Integrations',
                              compact: isMobile,
                              onTap: () =>
                                  setState(() => _selectedTab = 'Integrations'),
                            ),
                            const SizedBox(width: 8),
                            _SettingsTab(
                              label: 'Security',
                              icon: Icons.security_outlined,
                              isSelected: _selectedTab == 'Security',
                              compact: isMobile,
                              onTap: () =>
                                  setState(() => _selectedTab = 'Security'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tab Content
                    _buildSelectedContent(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedContent() {
    switch (_selectedTab) {
      case 'Profile':
        return _ProfileSection(org: _org, loading: _orgLoading);
      case 'Notifications':
        return _NotificationsSection(org: _org, loading: _orgLoading);
      case 'Integrations':
        return const _IntegrationsSection();
      case 'Security':
        return _SecuritySection(org: _org, loading: _orgLoading);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SettingsTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _SettingsTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          vertical: 10,
          horizontal: compact ? 12 : 20,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A5AE0) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF6A5AE0) : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6A5AE0).withAlpha(77),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatefulWidget {
  final Organization? org;
  final bool loading;

  const _ProfileSection({required this.org, required this.loading});

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  static const List<String> _orgTypes = [
    'Student Organization',
    'Non-Profit Organization',
    'Government Agency',
    'Private Company',
    'Public Institution',
    'Community Group',
    'Research Institute',
    'Other',
  ];

  final _firestoreService = FirestoreService();
  late TextEditingController _orgNameController;
  String _selectedOrgType = 'Student Organization';

  bool _aiAutoIntervention = true;
  bool _aiSmartScheduling = true;
  bool _aiBudgetAlerts = true;

  bool _saving = false;
  bool _initialized = false;

  void _syncFromOrg(Organization? org) {
    if (org == null || _initialized) return;
    _orgNameController.text = org.name;
    final savedType =
        (org.settings['orgType'] as String?) ?? 'Student Organization';
    _selectedOrgType = _orgTypes.contains(savedType)
        ? savedType
        : 'Student Organization';
    _aiAutoIntervention =
        (org.settings['ai_autoIntervention'] as bool?) ?? true;
    _aiSmartScheduling = (org.settings['ai_smartScheduling'] as bool?) ?? true;
    _aiBudgetAlerts = (org.settings['ai_budgetAlerts'] as bool?) ?? true;
    _initialized = true;
  }

  @override
  void initState() {
    super.initState();
    _orgNameController = TextEditingController();
    _syncFromOrg(widget.org);
  }

  @override
  void didUpdateWidget(_ProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initialized) _syncFromOrg(widget.org);
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _firestoreService.updateOrganization('demo_org', {
        'name': _orgNameController.text.trim(),
        'settings.orgType': _selectedOrgType,
        'settings.ai_autoIntervention': _aiAutoIntervention,
        'settings.ai_smartScheduling': _aiSmartScheduling,
        'settings.ai_budgetAlerts': _aiBudgetAlerts,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Organization Profile',
          subtitle: "Manage your organization's information and preferences",
          children: [
            _EditableInfoField(
              label: 'Organization Name',
              controller: _orgNameController,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Organization Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedOrgType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.withAlpha(51)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.withAlpha(51)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF6A5AE0)),
                    ),
                  ),
                  items: _orgTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedOrgType = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Number of Members',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withAlpha(51)),
                  ),
                  child: Text(
                    '${widget.org?.members.length ?? 0} members (managed via Firebase)',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionCard(
          title: 'AI Preferences',
          subtitle: "Configure how SetiaU's AI assistant behaves",
          children: [
            _SwitchRow(
              title: 'Auto-intervention',
              subtitle: 'AI suggests alternatives when constraints detected',
              initialValue: _aiAutoIntervention,
              onChanged: (v) => setState(() => _aiAutoIntervention = v),
            ),
            _SwitchRow(
              title: 'Smart scheduling',
              subtitle: 'Automatically check member availability',
              initialValue: _aiSmartScheduling,
              onChanged: (v) => setState(() => _aiSmartScheduling = v),
            ),
            _SwitchRow(
              title: 'Budget alerts',
              subtitle: 'Warn when approaching budget limits',
              initialValue: _aiBudgetAlerts,
              onChanged: (v) => setState(() => _aiBudgetAlerts = v),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 20),
            label: const Text(
              'Save Changes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A5AE0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              elevation: 4,
              shadowColor: const Color(0xFF6A5AE0).withAlpha(102),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _NotificationsSection extends StatefulWidget {
  final Organization? org;
  final bool loading;

  const _NotificationsSection({required this.org, required this.loading});

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  final _firestoreService = FirestoreService();

  bool _pendingApprovals = true;
  bool _meetingSummaries = true;
  bool _taskAssignments = true;
  bool _budgetUpdates = false;
  bool _weeklyDigest = true;
  bool _aiInterventions = true;
  bool _soundEffects = false;

  bool _saving = false;
  bool _initialized = false;

  void _syncFromOrg(Organization? org) {
    if (org == null || _initialized) return;
    final s = org.settings;
    _pendingApprovals = (s['notif_pendingApprovals'] as bool?) ?? true;
    _meetingSummaries = (s['notif_meetingSummaries'] as bool?) ?? true;
    _taskAssignments = (s['notif_taskAssignments'] as bool?) ?? true;
    _budgetUpdates = (s['notif_budgetUpdates'] as bool?) ?? false;
    _weeklyDigest = (s['notif_weeklyDigest'] as bool?) ?? true;
    _aiInterventions = (s['notif_aiInterventions'] as bool?) ?? true;
    _soundEffects = (s['notif_soundEffects'] as bool?) ?? false;
    _initialized = true;
  }

  @override
  void initState() {
    super.initState();
    _syncFromOrg(widget.org);
  }

  @override
  void didUpdateWidget(_NotificationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initialized) _syncFromOrg(widget.org);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _firestoreService.updateOrganization('demo_org', {
        'settings.notif_pendingApprovals': _pendingApprovals,
        'settings.notif_meetingSummaries': _meetingSummaries,
        'settings.notif_taskAssignments': _taskAssignments,
        'settings.notif_budgetUpdates': _budgetUpdates,
        'settings.notif_weeklyDigest': _weeklyDigest,
        'settings.notif_aiInterventions': _aiInterventions,
        'settings.notif_soundEffects': _soundEffects,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Email Notifications',
          subtitle: 'Choose what updates you want to receive',
          children: [
            _SwitchRow(
              title: 'Pending approvals',
              subtitle: 'Get notified when actions need approval',
              initialValue: _pendingApprovals,
              onChanged: (v) => setState(() => _pendingApprovals = v),
            ),
            _SwitchRow(
              title: 'Meeting summaries',
              subtitle: 'Receive auto-generated meeting minutes',
              initialValue: _meetingSummaries,
              onChanged: (v) => setState(() => _meetingSummaries = v),
            ),
            _SwitchRow(
              title: 'Task assignments',
              subtitle: 'Alert when new tasks are assigned',
              initialValue: _taskAssignments,
              onChanged: (v) => setState(() => _taskAssignments = v),
            ),
            _SwitchRow(
              title: 'Budget updates',
              subtitle: 'Notify on budget changes',
              initialValue: _budgetUpdates,
              onChanged: (v) => setState(() => _budgetUpdates = v),
            ),
            _SwitchRow(
              title: 'Weekly digest',
              subtitle: 'Summary of weekly activities',
              initialValue: _weeklyDigest,
              onChanged: (v) => setState(() => _weeklyDigest = v),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionCard(
          title: 'In-App Notifications',
          subtitle: 'Manage notifications within SetiaU',
          children: [
            _SwitchRow(
              title: 'AI interventions',
              subtitle: 'Show alerts during meetings',
              initialValue: _aiInterventions,
              onChanged: (v) => setState(() => _aiInterventions = v),
            ),
            _SwitchRow(
              title: 'Sound effects',
              subtitle: 'Play sounds for important alerts',
              initialValue: _soundEffects,
              onChanged: (v) => setState(() => _soundEffects = v),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 20),
            label: const Text(
              'Save Changes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A5AE0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              elevation: 4,
              shadowColor: const Color(0xFF6A5AE0).withAlpha(102),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _IntegrationsSection extends StatefulWidget {
  const _IntegrationsSection();

  @override
  State<_IntegrationsSection> createState() => _IntegrationsSectionState();
}

class _IntegrationsSectionState extends State<_IntegrationsSection> {
  bool _calendarConnected = false;
  bool _calendarLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCalendarStatus();
  }

  Future<void> _checkCalendarStatus() async {
    final connected = await GoogleCalendarService.isSignedIn();
    if (mounted) {
      setState(() {
        _calendarConnected = connected;
        _calendarLoading = false;
      });
    }
  }

  Future<void> _toggleCalendar() async {
    setState(() => _calendarLoading = true);
    try {
      if (_calendarConnected) {
        await GoogleCalendarService.signOut();
        if (mounted) {
          setState(() {
            _calendarConnected = false;
            _calendarLoading = false;
          });
        }
      } else {
        final account = await GoogleCalendarService.signInForCalendar();
        if (mounted) {
          setState(() {
            _calendarConnected = account != null;
            _calendarLoading = false;
          });
        }
        if (account != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Calendar connected!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Calendar sign-in was cancelled or failed.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _calendarLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? user?.displayName ?? 'Not signed in';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Google Workspace Integration',
          subtitle: 'Connect SetiaU with your Google services',
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Google Account',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Google Calendar — real connect/disconnect
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 24, color: Colors.grey[600]),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Google Calendar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1D1E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _calendarLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : ElevatedButton(
                          onPressed: _toggleCalendar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _calendarConnected
                                ? Colors.red[50]
                                : const Color(0xFF6A5AE0),
                            foregroundColor: _calendarConnected
                                ? Colors.red[700]
                                : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            _calendarConnected ? 'Disconnect' : 'Connect',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                ],
              ),
            ),
            _ComingSoonRow(title: 'Gmail', icon: Icons.mail_outline),
            _ComingSoonRow(
              title: 'Google Docs',
              icon: Icons.description_outlined,
            ),
            _ComingSoonRow(
              title: 'Google Sheets',
              icon: Icons.table_chart_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionCard(
          title: 'AI Model Configuration',
          subtitle: 'Gemini API settings',
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withAlpha(51)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gemini 2.0 Flash',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Active model · configured via GEMINI_API_KEY',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecuritySection extends StatefulWidget {
  final Organization? org;
  final bool loading;

  const _SecuritySection({required this.org, required this.loading});

  @override
  State<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<_SecuritySection> {
  final _firestoreService = FirestoreService();

  bool _requireApproval = true;
  bool _auditLogging = true;
  bool _twoFactor = false;
  int _retentionMonths = 12;

  bool _saving = false;
  bool _initialized = false;

  void _syncFromOrg(Organization? org) {
    if (org == null || _initialized) return;
    final s = org.settings;
    _requireApproval = (s['security_requireApproval'] as bool?) ?? true;
    _auditLogging = (s['security_auditLogging'] as bool?) ?? true;
    _twoFactor = (s['security_twoFactor'] as bool?) ?? false;
    _retentionMonths = (s['data_retentionMonths'] as int?) ?? 12;
    _initialized = true;
  }

  @override
  void initState() {
    super.initState();
    _syncFromOrg(widget.org);
  }

  @override
  void didUpdateWidget(_SecuritySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initialized) _syncFromOrg(widget.org);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _firestoreService.updateOrganization('demo_org', {
        'settings.security_requireApproval': _requireApproval,
        'settings.security_auditLogging': _auditLogging,
        'settings.security_twoFactor': _twoFactor,
        'settings.data_retentionMonths': _retentionMonths,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security settings saved.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _configureRetention() async {
    final options = [3, 6, 12, 24];
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Data Retention Period'),
        children: options
            .map(
              (m) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, m),
                child: Row(
                  children: [
                    if (_retentionMonths == m)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: Color(0xFF6A5AE0),
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text('$m months'),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _retentionMonths = picked);
    }
  }

  Future<void> _downloadData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Data export queued — you will receive an email when ready.',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _deleteData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Organization Data'),
        content: const Text(
          'This will permanently delete all meetings, tasks, actions and budgets for this organization. '
          'This action cannot be undone.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      // In a real implementation this would call a cloud function.
      // For now, show feedback.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deletion request submitted.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Security & Privacy',
          subtitle: 'Manage access controls and data privacy',
          children: [
            _SwitchRow(
              title: 'Require approval for all actions',
              subtitle: 'Human-in-the-loop for every execution',
              initialValue: _requireApproval,
              onChanged: (v) => setState(() => _requireApproval = v),
            ),
            _SwitchRow(
              title: 'Audit logging',
              subtitle: 'Keep detailed logs of all activities',
              initialValue: _auditLogging,
              onChanged: (v) => setState(() => _auditLogging = v),
            ),
            _SwitchRow(
              title: 'Two-factor authentication',
              subtitle: 'Add extra security layer',
              initialValue: _twoFactor,
              onChanged: (v) => setState(() => _twoFactor = v),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionCard(
          title: 'Data Management',
          subtitle: 'Control your organizational data',
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data retention period',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Currently: $_retentionMonths months',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                OutlinedButton(
                  onPressed: _configureRetention,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1D1E),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Configure'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Export your data',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloadData,
                icon: const Icon(Icons.storage_outlined, size: 18),
                label: const Text('Download All Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF1A1D1E),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Danger Zone',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.withAlpha(51)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: _deleteData,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Delete Organization Data',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A5AE0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Shared Widgets
// -----------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;
        final cardPadding = isNarrow ? 16.0 : 24.0;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withAlpha(51)),
          ),
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditableInfoField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _EditableInfoField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1D1E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 14, color: Color(0xFF4A4A4A)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withAlpha(51)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withAlpha(51)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6A5AE0)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    this.initialValue = true,
    this.onChanged,
  });

  @override
  State<_SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends State<_SwitchRow> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  void didUpdateWidget(_SwitchRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                if (widget.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      widget.subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: _value,
            onChanged: (val) {
              setState(() => _value = val);
              widget.onChanged?.call(val);
            },
            activeThumbColor: const Color(0xFF6A5AE0),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[200],
            trackOutlineColor: WidgetStateProperty.resolveWith((
              final Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return null;
              }
              return Colors.grey[300];
            }),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonRow extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ComingSoonRow({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[400]),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Coming soon',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
