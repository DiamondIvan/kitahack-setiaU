import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kitahack_setiau/services/auth_service.dart';
import 'package:kitahack_setiau/screens/meeting_mode_screen.dart';
import 'package:kitahack_setiau/screens/dashboard_mode_screen.dart';
import 'package:kitahack_setiau/screens/settings_screen.dart';
import 'package:kitahack_setiau/screens/memory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _currentTabIndex = 0;
  // 0: Meeting Mode, 1: Dashboard, 2: Settings

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A5AE0), Color(0xFF8F67E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.account_circle, color: Color(0xFF6A5AE0), size: 32),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('SetiaU', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('AI Secretary', style: TextStyle(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Navigation
                _SidebarItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  selected: _currentTabIndex == 1,
                  onTap: () => setState(() => _currentTabIndex = 1),
                ),
                _SidebarItem(
                  icon: Icons.mic,
                  label: 'Meeting Mode',
                  selected: _currentTabIndex == 0,
                  onTap: () => setState(() => _currentTabIndex = 0),
                ),
                _SidebarItem(
                  icon: Icons.storage, // Using storage as a placeholder for Memory
                  label: 'Memory',
                  selected: _currentTabIndex == 3,
                  onTap: () => setState(() => _currentTabIndex = 3),
                ),
                _SidebarItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  selected: _currentTabIndex == 2,
                  onTap: () => setState(() => _currentTabIndex = 2),
                ),
                const Spacer(),
                // User info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: const Text('D', style: TextStyle(color: Color(0xFF6A5AE0), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('demo@setiau.com', style: TextStyle(fontSize: 14, color: Colors.white)),
                          Text('Admin', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: InkWell(
                    onTap: () async {
                      await _authService.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.logout, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA),
              child: IndexedStack(
                index: _currentTabIndex,
                children: const [
                  MeetingModeScreen(),
                  DashboardModeScreen(),
                  SettingsScreen(),
                  MemoryScreen(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sidebar item widget at top level
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
