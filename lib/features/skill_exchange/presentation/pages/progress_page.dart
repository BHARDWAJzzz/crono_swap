import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/badge_service.dart';
import '../providers/auth_providers.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userDataProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('My Progress', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('No data'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // XP & Level Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Level ${user.level}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                              Text(user.levelTitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 18),
                                const SizedBox(width: 4),
                                Text('${user.streak} 🔥', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: user.levelProgress.clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${user.xp} / ${user.xpForNextLevel} XP',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Stats Grid
                Text('STATS', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard('${user.hoursTeaching}h', 'Hours Teaching', Icons.school_rounded, Colors.blue),
                    _buildStatCard('${user.hoursLearning}h', 'Hours Learning', Icons.menu_book_rounded, Colors.green),
                    _buildStatCard('${user.swapsCompleted}', 'Swaps Done', Icons.swap_horiz_rounded, Colors.purple),
                    _buildStatCard('${user.lecturesSold}', 'Lectures Sold', Icons.sell_rounded, Colors.orange),
                    _buildStatCard('${user.totalReviews}', 'Reviews', Icons.star_rounded, Colors.amber),
                    _buildStatCard('${user.timeBalance}h', 'Balance', Icons.timer_outlined, theme.colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 32),

                // Badges
                Text('BADGES', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: BadgeService.allBadges.values.map((badge) {
                    final earned = user.badgeIds.contains(badge.id);
                    return Container(
                      width: MediaQuery.of(context).size.width / 2 - 36,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: earned ? Colors.amber.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: earned ? Colors.amber.shade200 : Colors.grey.shade200,
                          width: earned ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(badge.icon, style: TextStyle(fontSize: 28, color: earned ? null : Colors.grey.shade300)),
                          const SizedBox(height: 8),
                          Text(
                            badge.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: earned ? Colors.grey.shade800 : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badge.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500, height: 1.3),
                          ),
                          if (!earned) ...[
                            const SizedBox(height: 4),
                            Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade300),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
        ],
      ),
    );
  }
}
