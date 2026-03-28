import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_providers.dart';
import '../../domain/entities/user.dart';
import 'edit_profile_page.dart';
import '../../../../core/widgets/shimmer_loader.dart';

class ProfilePage extends ConsumerWidget {
  final AppUser? user;
  const ProfilePage({super.key, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserDataAsync = ref.watch(userDataProvider);
    final theme = Theme.of(context);

    // Use the passed user or the current user
    final AppUser? displayUser = user ?? currentUserDataAsync.value;
    final bool isOwnProfile = user == null || (user?.id == currentUserDataAsync.value?.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'My Profile' : '${displayUser?.name}\'s Profile', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          if (isOwnProfile && displayUser != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => EditProfilePage(user: displayUser)),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: displayUser == null
          ? (currentUserDataAsync.isLoading 
              ? _buildLoadingState() 
              : const Center(child: Text('User profile not found')))
          : _buildProfileContent(context, ref, displayUser, theme, isOwnProfile),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, AppUser user, ThemeData theme, bool isOwnProfile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 54,
              backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.4),
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null 
                ? Icon(Icons.person_rounded, size: 54, color: theme.colorScheme.primary)
                : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user.name,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (user.bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                user.bio,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 32),

          // Reputation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.isVerifiedProfessional) ...[
                Icon(Icons.verified_rounded, size: 20, color: Colors.blue.shade400),
                const SizedBox(width: 6),
                Text('Verified', style: TextStyle(color: Colors.blue.shade400, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 16),
              ],
              Icon(Icons.star_rounded, size: 20, color: Colors.amber.shade600),
              const SizedBox(width: 4),
              Text(
                user.averageRating > 0 ? user.averageRating.toStringAsFixed(1) : 'N/A',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text('(${user.totalReviews})', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),

          // XP / Level Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary.withOpacity(0.08), theme.colorScheme.secondary.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('LVL ${user.level}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Text(user.levelTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, size: 18, color: Colors.orange.shade400),
                        const SizedBox(width: 4),
                        Text('${user.streak} streak', style: TextStyle(color: Colors.orange.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: user.levelProgress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${user.xp} / ${user.xpForNextLevel} XP',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Balance',
                  '${user.timeBalance}h',
                  Icons.timer_outlined,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Offers',
                  '${user.skillIds.length}',
                  Icons.auto_awesome_outlined,
                  theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (user.interests.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Interests',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.interests.map((interest) => Chip(
                  label: Text(interest, style: const TextStyle(fontSize: 12)),
                  backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                )).toList(),
              ),
            ),
          ],
          if (user.skillsWanted.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Looking to Learn',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.skillsWanted.map((skill) => Chip(
                  label: Text(skill, style: const TextStyle(fontSize: 12)),
                  avatar: const Icon(Icons.menu_book_rounded, size: 16),
                  backgroundColor: Colors.green.shade50,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                )).toList(),
              ),
            ),
          ],
          if (user.availability.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.availability.map((slot) => Chip(
                  label: Text(slot, style: const TextStyle(fontSize: 12)),
                  avatar: const Icon(Icons.schedule_rounded, size: 16),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                )).toList(),
              ),
            ),
          ],
          if (user.badgeIds.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Badges',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.badgeIds.map((badgeId) {
                  final badges = {
                    'top_mentor': '🎓 Top Mentor',
                    'fast_learner': '⚡ Fast Learner',
                    'generous': '💝 Generous',
                    'rising_star': '🌟 Rising Star',
                    'trusted': '✅ Trusted',
                    'streak_master': '🔥 Streak Master',
                  };
                  return Chip(
                    label: Text(badges[badgeId] ?? badgeId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.amber.shade50,
                    side: BorderSide(color: Colors.amber.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
              ),
            ),
          ],
          if (isOwnProfile) ...[
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const ShimmerLoader(width: 108, height: 108, borderRadius: 54),
          const SizedBox(height: 20),
          const ShimmerLoader(width: 200, height: 24, borderRadius: 8),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: const ShimmerLoader(width: double.infinity, height: 120, borderRadius: 24)),
              const SizedBox(width: 16),
              Expanded(child: const ShimmerLoader(width: double.infinity, height: 120, borderRadius: 24)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
