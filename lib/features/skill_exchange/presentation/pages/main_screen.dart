import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'explore_page.dart';
import 'swaps_page.dart';
import 'settings_page.dart';
import 'admin_page.dart';
import '../providers/auth_providers.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userDataAsync = ref.watch(userDataProvider);
    
    return userDataAsync.when(
      data: (user) {
        if (user != null && !user.isApproved) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified_user_outlined, size: 64, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Account Pending',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hi ${user.name}, our moderators are reviewing your ID and onboarding details. You\'ll have full access once approved!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => ref.read(authRepositoryProvider).signOut(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.red.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel & Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final bool isAdmin = user?.isSuperAdmin ?? false;

        final List<Widget> pages = [
          const DashboardPage(),
          const ExplorePage(),
          const SwapsPage(),
          const ProfilePage(),
          const SettingsPage(),
          if (isAdmin) const AdminPage(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: _selectedIndex >= pages.length ? 0 : _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: Colors.grey.shade400,
                selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 10),
                unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10),
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_filled),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    label: 'Explore',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.swap_horiz_rounded),
                    label: 'Swaps',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    label: 'Profile',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    label: 'Settings',
                  ),
                  if (isAdmin)
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.admin_panel_settings_outlined),
                      label: 'Admin',
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
