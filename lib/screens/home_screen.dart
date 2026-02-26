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
  bool _isSidebarExpanded = false;
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

        // 3. User is logged in! Show the new MVP Sidebar (Desktop) or Bottom Nav (Mobile) layout
        final user = snapshot.data!;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            if (isDesktop) {
              return Scaffold(
                backgroundColor: const Color(0xFFF5F6FA),
                body: Row(
                  children: [
                    // Desktop Sidebar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: _isSidebarExpanded ? 260.0 : 80.0,
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
                          // Toggle Button
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isSidebarExpanded = !_isSidebarExpanded;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(26),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _isSidebarExpanded
                                        ? Icons.menu_open
                                        : Icons.menu,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Navigation
                          _SidebarItem(
                            icon: Icons.dashboard,
                            label: 'Dashboard',
                            selected: _currentTabIndex == 1,
                            isExpanded: _isSidebarExpanded,
                            onTap: () => setState(() => _currentTabIndex = 1),
                          ),
                          _SidebarItem(
                            icon: Icons.mic,
                            label: 'Meeting Mode',
                            selected: _currentTabIndex == 0,
                            isExpanded: _isSidebarExpanded,
                            onTap: () => setState(() => _currentTabIndex = 0),
                          ),
                          _SidebarItem(
                            icon: Icons.storage,
                            label: 'Memory',
                            selected: _currentTabIndex == 3,
                            isExpanded: _isSidebarExpanded,
                            onTap: () => setState(() => _currentTabIndex = 3),
                          ),
                          _SidebarItem(
                            icon: Icons.settings,
                            label: 'Settings',
                            selected: _currentTabIndex == 2,
                            isExpanded: _isSidebarExpanded,
                            onTap: () => setState(() => _currentTabIndex = 2),
                          ),
                          const Spacer(),
                          // User info (only when expanded)
                          if (_isSidebarExpanded)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      (user.displayName?.isNotEmpty == true
                                              ? user.displayName![0]
                                              : (user.email?.isNotEmpty == true
                                                    ? user.email![0]
                                                    : 'U'))
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                          // Sign Out Button
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 24,
                              left: 16,
                              right: 16,
                            ),
                            child: _SidebarSignOutButton(
                              isExpanded: _isSidebarExpanded,
                              authService: _authService,
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
                            MeetingModeScreen(), // index 0
                            DashboardModeScreen(), // index 1
                            SettingsScreen(), // index 2
                            MemoryScreen(), // index 3
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Mobile View: Bottom Navigation Overlay
              return Scaffold(
                backgroundColor: const Color(0xFFF5F6FA),
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 90,
                        ), // Space for floating bottom bar
                        child: IndexedStack(
                          index: _currentTabIndex,
                          children: const [
                            MeetingModeScreen(), // index 0
                            DashboardModeScreen(), // index 1
                            SettingsScreen(), // index 2
                            MemoryScreen(), // index 3
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _BottomNavItem(
                              icon: Icons.dashboard_outlined,
                              activeIcon: Icons.dashboard,
                              label: 'Home',
                              isSelected: _currentTabIndex == 1,
                              onTap: () => setState(() => _currentTabIndex = 1),
                            ),
                            _BottomNavItem(
                              icon: Icons.mic_none,
                              activeIcon: Icons.mic,
                              label: 'Meeting',
                              isSelected: _currentTabIndex == 0,
                              onTap: () => setState(() => _currentTabIndex = 0),
                            ),
                            _BottomNavItem(
                              icon: Icons.storage_outlined,
                              activeIcon: Icons.storage,
                              label: 'Memory',
                              isSelected: _currentTabIndex == 3,
                              onTap: () => setState(() => _currentTabIndex = 3),
                            ),
                            _BottomNavItem(
                              icon: Icons.settings_outlined,
                              activeIcon: Icons.settings,
                              label: 'Settings',
                              isSelected: _currentTabIndex == 2,
                              onTap: () => setState(() => _currentTabIndex = 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF6A5AE0) : Colors.grey[400],
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF6A5AE0) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarSignOutButton extends StatelessWidget {
  final bool isExpanded;
  final AuthService authService;

  const _SidebarSignOutButton({
    required this.isExpanded,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            await authService.signOut();
            navigator.pushReplacementNamed('/login');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: Colors.white, size: 20),
                if (isExpanded) const SizedBox(width: 8),
                if (isExpanded)
                  const Text(
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
    );
  }
}

// Sidebar item widget at top level
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Tooltip(
        message: isExpanded ? '' : label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),

              padding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: isExpanded ? 20 : 16,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withAlpha(38)
                    : Colors.transparent,
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
                mainAxisAlignment: isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? Colors.white
                        : Colors.white.withAlpha(179),
                    size: 24,
                  ),
                  if (isExpanded) const SizedBox(width: 16),
                  if (isExpanded)
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.white.withAlpha(179),
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (isExpanded && selected)
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
      ),
    );
  }
}
