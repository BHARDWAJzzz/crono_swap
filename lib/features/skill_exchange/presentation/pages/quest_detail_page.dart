import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/quest.dart';
import '../providers/quest_providers.dart';
import '../providers/auth_providers.dart';

class QuestDetailPage extends ConsumerWidget {
  final Quest quest;

  const QuestDetailPage({super.key, required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(userDataProvider).value;
    final isCreator = user?.id == quest.createdBy;
    final hasApplied = user != null && quest.applicantIds.contains(user.id);
    final isAssigned = user?.id == quest.assignedTo;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Quest Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type & Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(quest.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${quest.typeEmoji} ${quest.typeLabel}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, color: _getTypeColor(quest.type)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(quest.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    quest.status.name.toUpperCase(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, color: _getStatusColor(quest.status)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              quest.title,
              style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),

            // Creator info
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: quest.creatorAvatarUrl != null ? NetworkImage(quest.creatorAvatarUrl!) : null,
                  child: quest.creatorAvatarUrl == null
                      ? Text(quest.creatorName.isNotEmpty ? quest.creatorName[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.creatorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      'Posted ${DateFormat('MMM d, yyyy').format(quest.createdAt)}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reward card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REWARD', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Text('${quest.creditReward} Crono Credits', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.timer_outlined, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Flash timer
            if (quest.isFlash && quest.expiresAt != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flash_on_rounded, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Flash Quest', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                          Text(
                            quest.isExpired
                                ? 'This quest has expired'
                                : 'Expires ${DateFormat('MMM d, HH:mm').format(quest.expiresAt!)}',
                            style: TextStyle(color: Colors.amber.shade700, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Description
            Text('DESCRIPTION', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Text(quest.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.6)),
            ),
            const SizedBox(height: 24),

            // Skill tags
            if (quest.skillTags.isNotEmpty) ...[
              Text('SKILLS NEEDED', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quest.skillTags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Applicants section (for creator)
            if (isCreator && quest.applicantIds.isNotEmpty) ...[
              Text('APPLICANTS (${quest.applicantIds.length})', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
              const SizedBox(height: 12),
              ...quest.applicantIds.map((applicantId) => _buildApplicantTile(context, ref, applicantId, quest)),
              const SizedBox(height: 24),
            ],

            // Action buttons
            if (quest.status == QuestStatus.open && !isCreator && !hasApplied && !quest.isExpired)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (user == null) return;
                    try {
                      await ref.read(questRepositoryProvider).applyToQuest(quest.id, user.id, user.name);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Applied! The quest owner will review your application.'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  icon: const Icon(Icons.volunteer_activism_rounded),
                  label: Text('Apply for this Quest', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                ),
              ),

            if (hasApplied && quest.status == QuestStatus.open)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('You\'ve applied! Waiting for the quest owner to assign.', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

            if (isCreator && quest.status == QuestStatus.active)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(questRepositoryProvider).completeQuest(quest.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quest completed! Credits transferred.'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text('Mark as Completed', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                ),
              ),

            if (isCreator && quest.status != QuestStatus.completed && quest.status != QuestStatus.cancelled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Cancel Quest?'),
                        content: const Text('Your escrowed credits will be refunded.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, cancel', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await ref.read(questRepositoryProvider).cancelQuest(quest.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Quest cancelled. Credits refunded.'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      }
                    }
                  },
                  child: Text('Cancel Quest', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantTile(BuildContext context, WidgetRef ref, String userId, Quest quest) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: ref.read(authRepositoryProvider).getUserData(userId),
      builder: (context, snapshot) {
        final applicant = snapshot.data;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: applicant?.avatarUrl != null ? NetworkImage(applicant!.avatarUrl!) : null,
                child: applicant?.avatarUrl == null
                    ? Text(applicant?.name.isNotEmpty == true ? applicant!.name[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(applicant?.name ?? 'Loading...', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    if (applicant != null)
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                          const SizedBox(width: 2),
                          Text('${applicant.averageRating.toStringAsFixed(1)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          const SizedBox(width: 8),
                          Text('Level ${applicant.level}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                  ],
                ),
              ),
              if (quest.status == QuestStatus.open)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(questRepositoryProvider).assignQuest(quest.id, userId, applicant?.name ?? 'User');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Assigned to ${applicant?.name ?? "user"}!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Assign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getTypeColor(QuestType type) {
    switch (type) {
      case QuestType.openBounty: return Colors.blue.shade700;
      case QuestType.flash: return Colors.orange.shade700;
      case QuestType.guild: return Colors.purple.shade700;
    }
  }

  Color _getStatusColor(QuestStatus status) {
    switch (status) {
      case QuestStatus.open: return Colors.green;
      case QuestStatus.active: return Colors.blue;
      case QuestStatus.completed: return Colors.purple;
      case QuestStatus.expired: return Colors.grey;
      case QuestStatus.cancelled: return Colors.red;
    }
  }
}
