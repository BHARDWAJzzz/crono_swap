import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Leaderboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('status', isEqualTo: 'approved')
            .orderBy('xp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No users yet'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final rank = index + 1;
              final isTopThree = rank <= 3;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isTopThree
                      ? [Colors.amber.shade50, Colors.grey.shade50, Colors.orange.shade50][index]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isTopThree
                        ? [Colors.amber.shade200, Colors.grey.shade300, Colors.orange.shade200][index]
                        : Colors.grey.shade100,
                    width: isTopThree ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 40,
                      child: isTopThree
                          ? Icon(
                              Icons.emoji_events_rounded,
                              color: [Colors.amber.shade600, Colors.grey.shade500, Colors.orange.shade600][index],
                              size: 28,
                            )
                          : Text(
                              '#$rank',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: data['avatarUrl'] != null ? NetworkImage(data['avatarUrl']) : null,
                      child: data['avatarUrl'] == null
                          ? Text(
                              (data['name'] ?? '?')[0].toUpperCase(),
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Name + Level
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                data['name'] ?? 'Unknown',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (data['isVerifiedProfessional'] == true) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.verified_rounded, size: 16, color: Colors.blue.shade400),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Level ${data['level'] ?? 1} • ${_getLevelTitle(data['level'] ?? 1)}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // XP + Rating
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${data['xp'] ?? 0} XP',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                            const SizedBox(width: 2),
                            Text(
                              (data['averageRating'] ?? 0).toStringAsFixed(1),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getLevelTitle(int level) {
    if (level >= 10) return 'Grandmaster';
    if (level >= 8) return 'Expert';
    if (level >= 6) return 'Advanced';
    if (level >= 4) return 'Intermediate';
    if (level >= 2) return 'Beginner';
    return 'Newcomer';
  }
}
