import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kitahack_setiau/services/google_calendar_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTab = 'Profile';

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
        return const _ProfileSection();
      case 'Notifications':
        return const _NotificationsSection();
      case 'Integrations':
        return const _IntegrationsSection();
      case 'Security':
        return const _SecuritySection();
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
  const _ProfileSection();

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  late TextEditingController _orgNameController;
  late TextEditingController _orgTypeController;
  late TextEditingController _membersController;
  late TextEditingController _timezoneController;

  @override
  void initState() {
    super.initState();
    _orgNameController = TextEditingController(
      text: 'University Student Council',
    );
    _orgTypeController = TextEditingController(text: 'Student Organization');
    _membersController = TextEditingController(text: '30');
    _timezoneController = TextEditingController(
      text: 'Asia/Kuala_Lumpur (GMT+8)',
    );
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _orgTypeController.dispose();
    _membersController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            _EditableInfoField(
              label: 'Organization Type',
              controller: _orgTypeController,
            ),
            const SizedBox(height: 16),
            _EditableInfoField(
              label: 'Number of Members',
              controller: _membersController,
            ),
            const SizedBox(height: 16),
            _EditableInfoField(
              label: 'Timezone',
              controller: _timezoneController,
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
              initialValue: true,
            ),
            _SwitchRow(
              title: 'Smart scheduling',
              subtitle: 'Automatically check member availability',
              initialValue: true,
            ),
            _SwitchRow(
              title: 'Budget alerts',
              subtitle: 'Warn when approaching budget limits',
              initialValue: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check, size: 20),
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

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
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
              initialValue: true,
            ),
            _SwitchRow(
              title: 'Meeting summaries',
              subtitle: 'Receive auto-generated meeting minutes',
              initialValue: true,
            ),
            _SwitchRow(
              title: 'Task assignments',
              subtitle: 'Alert when new tasks are assigned',
              initialValue: true,
            ),
            _SwitchRow(
              title: 'Budget updates',
              subtitle: 'Notify on budget changes',
              initialValue: false, // Matches screenshot
            ),
            _SwitchRow(
              title: 'Weekly digest',
              subtitle: 'Summary of weekly activities',
              initialValue: true,
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
              initialValue: true,
            ),
            _SwitchRow(
              title: 'Sound effects',
              subtitle: 'Play sounds for important alerts',
              initialValue: false, // Matches screenshot
            ),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check, size: 20),
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
            _SwitchRow(
              title: 'Gmail',
              subtitle: '',
              icon: Icons.mail_outline,
              initialValue: true,
              compact: true,
            ),
            _SwitchRow(
              title: 'Google Docs',
              subtitle: '',
              icon: Icons.description_outlined,
              initialValue: true,
              compact: true,
            ),
            _SwitchRow(
              title: 'Google Sheets',
              subtitle: '',
              icon: Icons.table_chart_outlined,
              initialValue: true,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionCard(
          title: 'AI Model Configuration',
          subtitle: "Gemini 3.0 Pro API settings",
          children: [
            // Placeholder for content not fully visible in screenshot
            const Text(
              'Gemini 3.0 Pro API settings',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecuritySection extends StatelessWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context) {
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
              initialValue: true,
            ),
            _SwitchRow(
              title: 'Audit logging',
              subtitle: 'Keep detailed logs of all activities',
              initialValue: true,
            ),
            _SwitchRow(
              title: 'Two-factor authentication',
              subtitle: 'Add extra security layer',
              initialValue: false, // Matches screenshot
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
                      'Currently: 12 months',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                OutlinedButton(
                  onPressed: () {},
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
                onPressed: () {},
                icon: const Icon(Icons.storage_outlined, size: 18),
                label: const Text('Download All Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9), // Light grey
                  foregroundColor: const Color(0xFF1A1D1E), // Dark text
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
                onPressed: () {},
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
            onPressed: () {},
            icon: const Icon(Icons.save_outlined, size: 18),
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
  final IconData? icon;
  final bool initialValue;
  final bool compact;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    this.initialValue = true,
    this.icon,
    this.compact = false,
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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.compact ? 12.0 : 16.0),
      child: Row(
        crossAxisAlignment: widget.compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 24, color: Colors.grey[600]),
            const SizedBox(width: 16),
          ],
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
            onChanged: (val) => setState(() => _value = val),
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
