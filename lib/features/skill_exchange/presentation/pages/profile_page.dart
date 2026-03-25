import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_providers.dart';

import 'edit_profile_page.dart';

import '../../../../core/widgets/shimmer_loader.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          userDataAsync.when(
            data: (user) => user != null 
              ? IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => EditProfilePage(user: user)),
                  ),
                )
              : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: userDataAsync.when(
        data: (user) => user == null
            ? const Center(child: Text('No user data found'))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                        child: Icon(Icons.person_rounded, size: 54, color: theme.colorScheme.primary),
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
                            backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          )).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        loading: () => SingleChildScrollView(
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
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15)),
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
