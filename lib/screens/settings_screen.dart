import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D2A4A))),
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
                      Text('Email Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2A4A))),
                      const SizedBox(height: 16),
                      _SwitchTile(title: 'Pending approvals', subtitle: 'Get notified when actions need approval'),
                      _SwitchTile(title: 'Meeting summaries', subtitle: 'Receive auto-generated meeting minutes'),
                      _SwitchTile(title: 'Task assignments', subtitle: 'Alert when new tasks are assigned'),
                      _SwitchTile(title: 'Budget updates', subtitle: 'Notify on budget changes'),
                      _SwitchTile(title: 'Weekly digest', subtitle: 'Summary of weekly activities'),
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
                      Text('In-App Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2A4A))),
                      const SizedBox(height: 16),
                      _SwitchTile(title: 'Action approvals', subtitle: 'Show pop-up for pending actions'),
                      _SwitchTile(title: 'Meeting reminders', subtitle: 'Remind before meeting starts'),
                      _SwitchTile(title: 'Task deadlines', subtitle: 'Notify before task due date'),
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
                      Text('Integrations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2A4A))),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.link, color: Color(0xFF6A5AE0)),
                        title: Text('Google Workspace'),
                        subtitle: Text('Connect calendar, docs, sheets'),
                        trailing: ElevatedButton(
                          onPressed: () {},
                          child: Text('Connect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6A5AE0),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.api, color: Color(0xFF8F67E8)),
                        title: Text('Gemini AI'),
                        subtitle: Text('Enable advanced AI features'),
                        trailing: ElevatedButton(
                          onPressed: () {},
                          child: Text('Enable'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8F67E8),
                            foregroundColor: Colors.white,
                          ),
                        ),
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
                      Text('Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2A4A))),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.lock, color: Color(0xFFE06767)),
                        title: Text('Change Password'),
                        trailing: ElevatedButton(
                          onPressed: () {},
                          child: Text('Change'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE06767),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.logout, color: Color(0xFF2D2A4A)),
                        title: Text('Sign Out'),
                        trailing: ElevatedButton(
                          onPressed: () {},
                          child: Text('Sign Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2D2A4A),
                            foregroundColor: Colors.white,
                          ),
                        ),
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
  }
}

class _SwitchTile extends StatefulWidget {
  final String title;
  final String subtitle;
  const _SwitchTile({required this.title, required this.subtitle, Key? key}) : super(key: key);

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: _value,
      onChanged: (val) => setState(() => _value = val),
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      activeColor: const Color(0xFF6A5AE0),
    );
  }
}
