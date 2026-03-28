import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'explore_page.dart';
import 'lectures_page.dart';
import 'swaps_page.dart';
import 'quests_page.dart';
import 'admin_page.dart';
import 'notification_center_page.dart';
import '../../../../core/services/gamification_service.dart';
import '../providers/auth_providers.dart';
import '../../domain/entities/user.dart';
import '../widgets/assistant_overlay.dart';
import '../../../../core/widgets/responsive_layout.dart';

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
    
    // Initialize notifications and check streak when user data is ready
    userDataAsync.whenData((user) {
      if (user != null) {
        // Run streak check once per session/day
        _checkStreak(user);
      }
    });
    
    return userDataAsync.when(
      data: (user) {
        if (user != null && user.status == 'suspended') {
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
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.gavel_rounded, size: 64, color: Colors.red.shade400),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Account Suspended',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please contact the administrator. Your account has been suspended.',
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
                      child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        if (user != null && !user.isApproved) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
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
          const QuestsPage(),
          const SwapsPage(),
          const ProfilePage(),
          if (isAdmin) const AdminPage(),
        ];

        final isMobile = ResponsiveLayout.isMobile(context);

        Widget bodyContent = IndexedStack(
          index: _selectedIndex,
          children: pages,
        );

        if (!isMobile) {
          bodyContent = Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex >= pages.length ? 0 : _selectedIndex,
                onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.white,
                selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
                selectedLabelTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 12),
                unselectedLabelTextStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 12),
                destinations: [
                  const NavigationRailDestination(icon: Icon(Icons.home_filled), label: Text('Home')),
                  const NavigationRailDestination(icon: Icon(Icons.explore_outlined), label: Text('Explore')),
                  const NavigationRailDestination(icon: Icon(Icons.auto_awesome_rounded), label: Text('Quests')),
                  const NavigationRailDestination(icon: Icon(Icons.swap_horiz_rounded), label: Text('Swaps')),
                  const NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Profile')),
                  if (isAdmin) const NavigationRailDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: Text('Admin')),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFEEEEEE)),
              Expanded(child: MaxWidthContainer(fillHeight: false, maxWidth: 1200, child: bodyContent)),
            ],
          );
        }

        return Scaffold(
          body: bodyContent,
          bottomNavigationBar: isMobile ? Container(
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
                  const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                  const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
                  const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'Quests'),
                  const BottomNavigationBarItem(icon: Icon(Icons.swap_horiz_rounded), label: 'Swaps'),
                  const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
                  if (isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
                ],
              ),
            ),
          ) : null,
          floatingActionButton: _selectedIndex == 0 
            ? FloatingActionButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AssistantOverlay(),
                ),
                heroTag: 'ai_assistant_fab',
                backgroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary.withOpacity(0.8), theme.colorScheme.secondary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                ),
              )
            : null,
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  void _checkStreak(AppUser user) async {
    final gamification = GamificationService();
    final updates = gamification.computeStreakUpdate(userData: user.toFirestore());
    
    // Only update if there are changes (e.g. today's date update or streak change)
    if (updates.isNotEmpty) {
      try {
        await ref.read(authRepositoryProvider).updateUserFields(user.id, updates);
      } catch (e) {
        debugPrint('Error updating streak: $e');
      }
    }
  }
}
