import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kitahack_setiau/services/auth_service.dart';
import 'package:kitahack_setiau/screens/meeting_mode_screen.dart';
import 'package:kitahack_setiau/screens/dashboard_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          Future.microtask(() {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('SetiaU'),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Profile'),
                    onTap: () {},
                  ),
                  PopupMenuItem(
                    child: const Text('Settings'),
                    onTap: () {},
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    child: const Text('Sign Out'),
                    onTap: () async {
                      await _authService.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentTabIndex,
            children: const [
              MeetingModeScreen(),
              DashboardModeScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.mic),
                label: 'Meeting Mode',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
            ],
          ),
        );
      },
    );
  }
}
