import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_providers.dart';
import 'package:fl_chart/fl_chart.dart';

class PublicProfilePage extends ConsumerWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return FutureBuilder<AppUser?>(
      future: ref.read(authRepositoryProvider).getUserData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('User not found')));
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_rounded),
                onPressed: () => _showQRDialog(context, user),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () => Share.share('Check out my Crono Swap profile: https://cronoswap.app/u/${user.id}'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildProfileHeader(theme, user),
                const SizedBox(height: 32),
                _buildStatsGrid(theme, user),
                const SizedBox(height: 32),
                _buildEndorsementsSection(theme, user),
                const SizedBox(height: 32),
                _buildBadgesSection(theme, user),
                const SizedBox(height: 32),
                _buildSwapHistorySection(theme, user),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(ThemeData theme, AppUser user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? Text(user.name[0], style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))
                    : null,
              ),
            ),
            if (user.isVerifiedProfessional)
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          user.name,
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Level ${user.level} • ${user.levelTitle}',
          style: GoogleFonts.outfit(fontSize: 16, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (user.bio.isNotEmpty)
          Text(
            user.bio,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
          ),
      ],
    );
  }

  Widget _buildStatsGrid(ThemeData theme, AppUser user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('🔥 ${user.streak}', 'STREAK'),
          _statItem('${user.swapsCompleted}', 'SWAPS'),
          _statItem('${user.averageRating.toStringAsFixed(1)}★', 'RATING'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildEndorsementsSection(ThemeData theme, AppUser user) {
    final endorsements = user.endorsements;
    if (endorsements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SKILL ENDORSEMENTS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: endorsements.entries.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: theme.colorScheme.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(6)),
                  child: Text('${e.value}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(ThemeData theme, AppUser user) {
    if (user.badgeIds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VERIFIED BADGES', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: user.badgeIds.length,
            itemBuilder: (context, index) {
              final badgeId = user.badgeIds[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.emoji_events_rounded, color: Colors.amber.shade700, size: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badgeId.replaceAll('_', ' ').toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSwapHistorySection(ThemeData theme, AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT SWAPS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.history_rounded, color: Colors.grey, size: 32),
              const SizedBox(height: 12),
              Text(
                'Completed ${user.swapsCompleted} skill swaps since ${DateFormat('MMMM yyyy').format(DateTime.now())}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showQRDialog(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SCAN TO CONNECT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 24),
            QrImageView(
              data: 'https://cronoswap.app/u/${user.id}',
              version: QrVersions.auto,
              size: 200.0,
              gapless: false,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
            ),
            const SizedBox(height: 24),
            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('crono-swap/${user.id.substring(0, 8)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
