import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/quest.dart';
import '../providers/quest_providers.dart';
import '../providers/auth_providers.dart';
import 'quest_detail_page.dart';

class QuestsPage extends ConsumerStatefulWidget {
  const QuestsPage({super.key});

  @override
  ConsumerState<QuestsPage> createState() => _QuestsPageState();

  static void showCreateQuestSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final creditsController = TextEditingController();
    final tagController = TextEditingController();
    final tags = <String>[];
    QuestType selectedType = QuestType.openBounty;
    bool isFlash = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Post a Quest', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Describe what you need — someone will pick it up', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 24),

                // Type selector
                Row(
                  children: [
                    _typeChip(context, setSheetState, selectedType, QuestType.openBounty, '🎯 Bounty', () => setSheetState(() { selectedType = QuestType.openBounty; isFlash = false; })),
                    const SizedBox(width: 8),
                    _typeChip(context, setSheetState, selectedType, QuestType.flash, '⚡ Flash', () => setSheetState(() { selectedType = QuestType.flash; isFlash = true; })),
                  ],
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Quest Title',
                    hintText: 'e.g., Need Flutter tutoring for 2hrs',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'What exactly do you need help with?',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: creditsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Credit Reward',
                    hintText: 'e.g., 2',
                    prefixIcon: const Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                // Tags
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagController,
                        decoration: InputDecoration(
                          labelText: 'Skill Tags',
                          hintText: 'e.g., Flutter',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        final tag = tagController.text.trim();
                        if (tag.isNotEmpty && !tags.contains(tag)) {
                          setSheetState(() => tags.add(tag));
                          tagController.clear();
                        }
                      },
                      icon: const Icon(Icons.add_circle_rounded),
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: tags.map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => setSheetState(() => tags.remove(t)),
                      deleteIconColor: Colors.red.shade300,
                      backgroundColor: Colors.grey.shade50,
                      side: BorderSide.none,
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _submitQuest(context, ref, ctx, titleController.text, descController.text, creditsController.text, tags, selectedType, isFlash),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text('Post Quest', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _typeChip(BuildContext context, StateSetter setSheetState, QuestType current, QuestType type, String label, VoidCallback onTap) {
    final isSelected = current == type;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  static Future<void> _submitQuest(BuildContext context, WidgetRef ref, BuildContext ctx, String title, String desc, String credits, List<String> tags, QuestType type, bool isFlash) async {
    if (title.trim().isEmpty || desc.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red));
      return;
    }
    final creditAmount = double.tryParse(credits);
    if (creditAmount == null || creditAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid credit amount'), backgroundColor: Colors.red));
      return;
    }

    final user = ref.read(userDataProvider).value;
    if (user == null) return;

    final quest = Quest(
      id: const Uuid().v4(),
      type: type,
      createdBy: user.id,
      creatorName: user.name,
      creatorAvatarUrl: user.avatarUrl,
      title: title.trim(),
      description: desc.trim(),
      skillTags: tags,
      creditReward: creditAmount,
      expiresAt: isFlash ? DateTime.now().add(const Duration(hours: 24)) : null,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(questRepositoryProvider).createQuest(quest);
      if (ctx.mounted) Navigator.pop(ctx);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quest posted! $creditAmount credits escrowed.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 100,
            left: 10,
            right: 10,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Quest Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 100,
            left: 10,
            right: 10,
          ),
        ),
      );
    }
  }
}

class _QuestsPageState extends ConsumerState<QuestsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('CRONO QUESTS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey.shade400,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
          tabs: const [
            Tab(text: 'BOUNTIES'),
            Tab(text: 'FLASH ⚡'),
            Tab(text: 'MY QUESTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestList(ref.watch(openQuestsProvider)),
          _buildQuestList(ref.watch(flashQuestsProvider)),
          _buildQuestList(ref.watch(userQuestsProvider)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuestsPage.showCreateQuestSheet(context, ref),
        heroTag: 'post_quest_fab',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Post Quest', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildQuestList(AsyncValue<List<Quest>> questsAsync) {
    return questsAsync.when(
      data: (quests) {
        if (quests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_off_rounded, size: 80, color: Colors.grey.shade200),
                const SizedBox(height: 24),
                Text(
                  'No quests yet.\nBe the first to post one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 16, height: 1.5),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: quests.length,
          itemBuilder: (context, index) => _buildQuestCard(quests[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildQuestCard(Quest quest) {
    final theme = Theme.of(context);
    final isExpired = quest.isExpired;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuestDetailPage(quest: quest)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isExpired ? Colors.grey.shade200 : quest.isFlash
                ? Colors.amber.shade200
                : Colors.grey.shade100,
            width: quest.isFlash ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getTypeColor(quest.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${quest.typeEmoji} ${quest.typeLabel}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _getTypeColor(quest.type),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${quest.creditReward} Credits',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                quest.title,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              const SizedBox(height: 8),
              Text(
                quest.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              if (quest.skillTags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quest.skillTags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(tag, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  )).toList(),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: quest.creatorAvatarUrl != null ? NetworkImage(quest.creatorAvatarUrl!) : null,
                    child: quest.creatorAvatarUrl == null
                        ? Text(quest.creatorName.isNotEmpty ? quest.creatorName[0] : '?', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(quest.creatorName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (quest.isFlash && quest.timeRemaining != null && !isExpired)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: Colors.orange.shade600),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(quest.timeRemaining!),
                          style: TextStyle(color: Colors.orange.shade600, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${quest.applicantIds.length} applied',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(QuestType type) {
    switch (type) {
      case QuestType.openBounty:
        return Colors.blue.shade700;
      case QuestType.flash:
        return Colors.orange.shade700;
      case QuestType.guild:
        return Colors.purple.shade700;
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m left';
    if (d.inMinutes > 0) return '${d.inMinutes}m left';
    return 'Expiring soon';
  }
}
