import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/skill.dart';
import '../widgets/exchange_bottom_sheet.dart';
import '../providers/auth_providers.dart';

class SkillDetailPage extends ConsumerWidget {
  final Skill skill;
  final String? heroTag;

  const SkillDetailPage({super.key, required this.skill, this.heroTag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(skill.category),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: heroTag ?? 'skill_${skill.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  skill.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Time Value: ${skill.timeValue} Crono Units',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            userAsync.when(
              data: (user) {
                if (user != null && user.timeBalance < skill.timeValue && user.id != skill.providerId) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Insufficient balance. Earn more time by teaching your skills!',
                            style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text(
              'About this Skill',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              skill.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Provider Info',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondary,
                backgroundImage: skill.providerAvatarUrl != null ? NetworkImage(skill.providerAvatarUrl!) : null,
                child: skill.providerAvatarUrl == null 
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
              ),
              title: Text(skill.providerName),
              subtitle: const Text('Top Rated Provider'),
              trailing: const Icon(Icons.verified, color: Colors.blue),
            ),
          ],
        ),
      ),
      bottomNavigationBar: userAsync.when(
        data: (user) {
          final isOwner = user?.id == skill.providerId;
          final hasBalance = (user?.timeBalance ?? 0) >= skill.timeValue;
          
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: (isOwner || !hasBalance) ? null : () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  builder: (context) => ExchangeBottomSheet(skill: skill),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: isOwner ? Colors.grey.shade200 : theme.colorScheme.primary,
                foregroundColor: isOwner ? Colors.grey.shade500 : Colors.white,
              ),
              child: Text(isOwner ? 'Your Own Skill' : 'Initiate Skill Swap'),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
