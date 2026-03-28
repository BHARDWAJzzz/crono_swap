import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/scale_on_tap.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/skill.dart';
import '../providers/auth_providers.dart';
import '../providers/skill_providers.dart';
import '../widgets/add_skill_bottom_sheet.dart';
import 'transaction_history_page.dart';
import 'notification_center_page.dart';
import 'quests_page.dart';
import 'smart_match_page.dart';
import 'progress_page.dart';
import '../providers/notification_providers.dart';
import '../providers/quest_providers.dart';

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
                  const SizedBox(height: 20),
                  _buildOverviewSection(theme, skillsAsync, userDataAsync),
                  const SizedBox(height: 24),
                  _buildQuickActions(context, theme),
                  const SizedBox(height: 24),
                  _buildQuestSummary(context, theme),
                  const SizedBox(height: 24),
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
                Row(
                  children: [
                    ref.watch(unreadNotificationCountProvider).when(
                      data: (count) => Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationCenterPage())),
                          ),
                          if (count > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      loading: () => const Icon(Icons.notifications_none_rounded, color: Colors.white70),
                      error: (_, __) => const Icon(Icons.notifications_none_rounded, color: Colors.white70),
                    ),
                    IconButton(
                      icon: const Icon(Icons.history_rounded, color: Colors.white70),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TransactionHistoryPage())),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            userData.when(
              data: (user) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Good ${now.hour < 12 ? "morning" : "evening"},\n${user?.name.split(' ')[0] ?? "Friend"}!',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      if (user != null && user.streak > 0)
                        _buildStreakWidget(theme, user),
                    ],
                  ),
                ],
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

  Widget _buildOverviewSection(ThemeData theme, AsyncValue<List<Skill>> skillsAsync, AsyncValue<AppUser?> userDataAsync) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          userDataAsync.when(
            data: (user) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Level ${user?.level ?? 1} ${user?.levelTitle ?? 'Newcomer'}', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Text('${user?.swapsCompleted ?? 0} Swaps Done', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            loading: () => const SizedBox(height: 40),
            error: (e, s) => const Text('Error loading stats'),
          ),
          const SizedBox(height: 20),
          userDataAsync.when(
            data: (user) => Row(
              children: [
                Expanded(child: ScaleOnTapWidget(child: _buildStatCard(theme, 'Learning', '${user?.boughtLectureIds.length ?? 0} Lectures', 'Mastering new skills', Icons.school_rounded))),
                const SizedBox(width: 16),
                Expanded(child: ScaleOnTapWidget(child: _buildStatCard(theme, 'Teaching', '${user?.lecturesSold ?? 0} Sold', 'Sharing knowledge', Icons.record_voice_over_rounded, isHighlight: true))),
              ],
            ),
            loading: () => const SizedBox(height: 100),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          userDataAsync.when(
            data: (user) => _buildActivityChart(theme, user),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(ThemeData theme, AppUser? user) {
    if (user == null) return const SizedBox.shrink();
    
    final teachingHours = user.hoursTeaching.toDouble();
    final learningHours = user.hoursLearning.toDouble();
    final maxHours = (teachingHours > learningHours ? teachingHours : learningHours) + 5;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Analytics',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StatefulBuilder(
              builder: (context, setChartState) {
                int touchedGroupIndex = -1;
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxHours == 5 ? 10 : maxHours, // Give some headroom
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (!event.isInterestedForInteractions ||
                            barTouchResponse == null ||
                            barTouchResponse.spot == null) {
                          setChartState(() {
                            touchedGroupIndex = -1;
                          });
                          return;
                        }
                        setChartState(() {
                          touchedGroupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                        });
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => theme.colorScheme.primary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} Hrs\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            children: <TextSpan>[
                              TextSpan(
                                text: group.x == 0 ? 'Teaching' : 'Learning',
                                style: TextStyle(color: theme.colorScheme.secondary, fontSize: 10, fontWeight: FontWeight.normal),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                value.toInt() == 0 ? 'Teaching' : 'Learning',
                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: teachingHours,
                            color: theme.colorScheme.primary,
                            width: touchedGroupIndex == 0 ? 40 : 32,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: learningHours,
                            color: theme.colorScheme.secondary,
                            width: touchedGroupIndex == 1 ? 40 : 32,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 250),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, String subtitle, IconData icon, {bool isHighlight = false}) {
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
              icon,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, height: 1.2),
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

  Widget _buildStreakWidget(ThemeData theme, AppUser user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            '🔥 ${user.streak}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          Text(
            'STREAK',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontWeight: FontWeight.w900,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickActionItem(context, theme, Icons.auto_awesome_rounded, 'Smart Match', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartMatchPage()))),
              _quickActionItem(context, theme, Icons.assignment_rounded, 'Post Quest', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestsPage()))),
              _quickActionItem(context, theme, Icons.insights_rounded, 'My Progress', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressPage()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionItem(BuildContext context, ThemeData theme, IconData icon, String label, VoidCallback onTap) {
    return ScaleOnTapWidget(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestSummary(BuildContext context, ThemeData theme) {
    final questsAsync = ref.watch(openQuestsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: questsAsync.when(
          data: (quests) {
            final flashQuests = quests.where((q) => q.isFlash).toList();
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CRONO QUESTS',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${quests.length} active bounties',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (flashQuests.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${flashQuests.length} FLASH QUESTS ⚡',
                            style: TextStyle(color: theme.colorScheme.secondary, fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestsPage())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('VIEW ALL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                ),
              ],
            );
          },
          loading: () => const ShimmerLoader(width: 200, height: 60, borderRadius: 24),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

