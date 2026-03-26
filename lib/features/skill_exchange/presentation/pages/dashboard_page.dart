import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/skill.dart';
import '../providers/auth_providers.dart';
import '../providers/skill_providers.dart';
import '../widgets/add_skill_bottom_sheet.dart';
import 'transaction_history_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(skillListProvider);
    final userDataAsync = ref.watch(userDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: CustomScrollView(
        slivers: [
          _buildHeader(userDataAsync, theme),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(theme, skillsAsync),
                  _buildRecentActivity(theme, skillsAsync),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddSkillBottomSheet(),
          );
        },
        backgroundColor: theme.colorScheme.secondary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<AppUser?> userData, ThemeData theme) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMM d').format(now);

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          image: DecorationImage(
            image: const AssetImage('assets/images/logo.png'),
            opacity: 0.05,
            alignment: Alignment.centerRight,
            scale: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CRONO SWAP',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const Icon(Icons.notifications_none_rounded, color: Colors.white70),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: Colors.white70),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TransactionHistoryPage())),
                ),
              ],
            ),
            const SizedBox(height: 40),
            userData.when(
              data: (user) => Text(
                'Good ${now.hour < 12 ? "morning" : "evening"},\n${user?.name.split(' ')[0] ?? "Friend"}!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
              loading: () => const ShimmerLoader(width: 150, height: 32, borderRadius: 8),
              error: (e, s) => const SizedBox(height: 35),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formattedDate,
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 12),
          Text(
            'Search',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          const Spacer(),
          Icon(Icons.qr_code_scanner_rounded, color: Colors.white.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(ThemeData theme, AsyncValue<List<Skill>> skillsAsync) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          skillsAsync.when(
            data: (skills) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Swap Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Total Skills: ${skills.length}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                Text('Active Trades: 0', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            loading: () => const SizedBox(height: 40),
            error: (e, s) => const Text('Error loading skills'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildOverviewCard(theme, 'Python Coding', 'Master programming & algorithms', '48 Lessons | 85% Complete')),
              const SizedBox(width: 16),
              Expanded(child: _buildOverviewCard(theme, 'UI/UX Design', 'Create beautiful user interfaces', '62 Lessons | 70% Complete', isHighlight: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(ThemeData theme, String title, String subtitle, String status, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isHighlight ? Icons.brush_rounded : Icons.code_rounded,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: TextStyle(color: theme.colorScheme.secondary, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Center(
                child: Text('Continue', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme, AsyncValue<List<Skill>> skillsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          skillsAsync.when(
            data: (skills) {
              final recentSkills = skills.reversed.take(3).toList();
              if (recentSkills.isEmpty) {
                return const Text('No recent activity found.');
              }
              return Column(
                children: recentSkills.map((s) => _buildActivityItem('Skill Offered: ${s.title}')).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => const Text('Error loading activity'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
