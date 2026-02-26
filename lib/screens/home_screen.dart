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
  late final Stream<User?> _authStream;
  int _currentTabIndex = 1;
  // 0: Meeting Mode, 1: Dashboard, 2: Settings, 3: Memory

  @override
  void initState() {
    super.initState();
    _authStream = _authService.authStateChanges;
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        // 1. Show loading spinner while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Redirect to login if they are not authenticated
        if (!snapshot.hasData) {
          _redirectToLogin();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 3. User is logged in! Show the new MVP Sidebar layout
        final user = snapshot.data!;
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Row(
            children: [
              // Sidebar
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final sidebarWidth = screenWidth > 1200 ? 260.0 : (screenWidth > 800 ? 240.0 : 200.0);
                  
                  return Container(
                    width: sidebarWidth,
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 32,
                            horizontal: 24,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.account_circle,
                                  color: Color(0xFF6A5AE0),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'SetiaU',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'AI Secretary',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
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
                          icon: Icons.storage,
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
                                child: Text(
                                  // FIX (Bug 3): Guard against empty string before indexing
                                  (user.displayName?.isNotEmpty == true
                                          ? user.displayName![0]
                                          : (user.email?.isNotEmpty == true ? user.email![0] : 'U'))
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF6A5AE0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.email ?? 'No email',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      user.displayName ?? 'Member',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 24,
                            left: 16,
                            right: 16,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(51)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  final navigator = Navigator.of(context);
                                  await _authService.signOut();
                                  if (!mounted) return;
                                  navigator.pushReplacementNamed('/login');
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.logout,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Sign Out',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Main content
              Expanded(
                child: Container(
                  color: const Color(0xFFF5F6FA),
                  child: IndexedStack(
                    index: _currentTabIndex,
                    // FIX (Bug 2): Reordered to match tab indices comment above:
                    // 0: Meeting Mode, 1: Dashboard, 2: Settings, 3: Memory
                    children: const [
                      MeetingModeScreen(),    // index 0
                      DashboardModeScreen(),  // index 1
                      SettingsScreen(),       // index 2
                      MemoryScreen(),         // index 3
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withAlpha(38) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : Colors.white.withAlpha(179),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withAlpha(179),
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                if (selected) const Spacer(),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}