import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_providers.dart';

class ResumeBuilderPage extends ConsumerWidget {
  const ResumeBuilderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userDataProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Resume Builder', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          userAsync.when(
            data: (user) => user != null
                ? IconButton(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () => _shareResume(context, user.name, user.id),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('No data'));

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getResumeEntries(user.id),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.description_rounded, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Auto-Generated Experience',
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Based on your Crono Swap activity. Share this with employers or add to your CV.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Summary stats
                    Text('SUMMARY', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryRow('⏱️ Total Teaching Hours', '${user.hoursTeaching}h'),
                          _buildSummaryRow('📚 Total Learning Hours', '${user.hoursLearning}h'),
                          _buildSummaryRow('🔄 Swaps Completed', '${user.swapsCompleted}'),
                          _buildSummaryRow('⭐ Average Rating', user.averageRating > 0 ? '${user.averageRating.toStringAsFixed(1)}/5.0' : 'N/A'),
                          _buildSummaryRow('🏆 Level', 'Level ${user.level} (${user.levelTitle})'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Experience entries
                    Text('EXPERIENCE', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
                    const SizedBox(height: 12),

                    if (entries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Complete swaps and buy lectures to build your resume!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      ...entries.map((entry) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (entry['type'] == 'teaching' ? Colors.blue : Colors.green).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    entry['type'] == 'teaching' ? Icons.school_rounded : Icons.menu_book_rounded,
                                    color: entry['type'] == 'teaching' ? Colors.blue : Colors.green,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry['title'] ?? '',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry['subtitle'] ?? '',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _shareResume(context, user.name, user.id),
                        icon: const Icon(Icons.share_rounded),
                        label: Text('Share Resume', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getResumeEntries(String userId) async {
    final entries = <Map<String, dynamic>>[];

    // Get completed swaps
    final sentSwaps = await FirebaseFirestore.instance
        .collection('swaps')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();
    final receivedSwaps = await FirebaseFirestore.instance
        .collection('swaps')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();

    for (final doc in sentSwaps.docs) {
      final data = doc.data();
      entries.add({
        'type': 'learning',
        'title': 'Learned: ${data['skillTitle'] ?? 'Skill'}',
        'subtitle': 'From ${data['receiverName']} • ${data['timeValue']} hours',
      });
    }
    for (final doc in receivedSwaps.docs) {
      final data = doc.data();
      entries.add({
        'type': 'teaching',
        'title': 'Taught: ${data['skillTitle'] ?? 'Skill'}',
        'subtitle': 'To ${data['senderName']} • ${data['timeValue']} hours',
      });
    }

    // Get bought lectures
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final boughtIds = List<String>.from(userDoc.data()?['boughtLectureIds'] ?? []);
    if (boughtIds.isNotEmpty) {
      final lectures = await FirebaseFirestore.instance
          .collection('lectures')
          .where(FieldPath.documentId, whereIn: boughtIds.take(10).toList())
          .get();
      for (final doc in lectures.docs) {
        final data = doc.data();
        entries.add({
          'type': 'learning',
          'title': 'Completed Lecture: ${data['title'] ?? 'Lecture'}',
          'subtitle': 'By ${data['providerName']} • ${data['priceInHours']} hours',
        });
      }
    }

    return entries;
  }

  void _shareResume(BuildContext context, String name, String userId) async {
    final entries = await _getResumeEntries(userId);
    final buffer = StringBuffer();
    buffer.writeln('📋 $name — Crono Swap Resume\n');
    buffer.writeln('---');
    for (final entry in entries) {
      buffer.writeln('• ${entry['title']}');
      buffer.writeln('  ${entry['subtitle']}');
    }
    buffer.writeln('\n🔗 Generated via Crono Swap');

    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }
}
