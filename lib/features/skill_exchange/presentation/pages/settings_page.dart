import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_providers.dart';
import 'edit_profile_page.dart';
import 'buy_credits_page.dart';
import 'leaderboard_page.dart';
import 'donate_credits_page.dart';
import 'progress_page.dart';
import 'resume_builder_page.dart';
import 'transaction_history_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(userDataProvider).value;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSection(
              theme,
              'Account',
              [
                _buildSettingItem(Icons.person_outline_rounded, 'Profile Information', () {
                  if (user != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfilePage(user: user)));
                  }
                }),
                _buildSettingItem(Icons.notifications_none_rounded, 'Notifications', () {}),
                _buildSettingItem(Icons.lock_outline_rounded, 'Security', () {}),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              'Economy',
              [
                _buildSettingItem(Icons.timer_outlined, 'Buy Crono Hours', () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const BuyCreditsPage()));
                }),
                _buildSettingItem(Icons.volunteer_activism_rounded, 'Donate Credits', () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const DonateCreditsPage()));
                }),
                _buildSettingItem(Icons.receipt_long_rounded, 'Transaction History', () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const TransactionHistoryPage()));
                }),
                _buildSettingItem(Icons.leaderboard_rounded, 'Leaderboard', () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const LeaderboardPage()));
                }),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              'Activity',
              [
                _buildSettingItem(Icons.bar_chart_rounded, 'My Progress', () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const ProgressPage()));
                }),
                _buildSettingItem(Icons.description_rounded, 'Resume Builder', () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const ResumeBuilderPage()));
                }),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              'App Settings',
              [
                _buildSettingItem(Icons.dark_mode_outlined, 'Appearance', () {}),
                _buildSettingItem(Icons.language_rounded, 'Language', () {}),
              ],
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Crono Swap v1.0.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.grey.shade700, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
