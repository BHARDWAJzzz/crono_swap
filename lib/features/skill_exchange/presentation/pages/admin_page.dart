import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/skill_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_config_page.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillListProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text('Admin Console', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade900,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(skillListProvider),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.red.shade900,
            unselectedLabelColor: Colors.red.withValues(alpha: 0.5),
            indicatorColor: Colors.red.shade900,
            tabs: const [
              Tab(text: 'Content'),
              Tab(text: 'User Access'),
              Tab(text: 'Config'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildContentTab(theme, skillsAsync),
            _buildUserAccessTab(theme, ref),
            const AdminConfigPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTab(ThemeData theme, AsyncValue<List<dynamic>> skillsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStats(theme, skillsAsync),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Manage All Content',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: skillsAsync.when(
            data: (skills) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: skills.length,
              itemBuilder: (context, index) {
                final skill = skills[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(skill.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('By ${skill.providerName}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () {},
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildUserAccessTab(ThemeData theme, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 64, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text('No pending user requests', style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final userId = docs[index].id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text('PENDING', style: TextStyle(color: Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(data['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    if (data['bio'] != null) ...[
                      const SizedBox(height: 12),
                      Text(data['bio'], style: const TextStyle(fontSize: 13, height: 1.4)),
                    ],
                    const SizedBox(height: 20),
                    _buildVerificationLinks(data),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateUserStatus(userId, 'rejected'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateUserStatus(userId, 'approved'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'status': status});
  }

  Widget _buildStats(ThemeData theme, AsyncValue<List<dynamic>> skills) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.red.shade50,
      child: Row(
        children: [
          _buildStatItem('Skills', skills.when(data: (s) => s.length.toString(), loading: () => '...', error: (e, s) => '0')),
          const SizedBox(width: 40),
          _buildStatItem('Reports', '0'),
          const SizedBox(width: 40),
          _buildStatItem('Flags', '2'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
      ],
    );
  }

  Widget _buildVerificationLinks(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VERIFICATION DOCUMENTS',
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (data['linkedinUrl'] != null)
              _VerificationChip(
                label: 'LinkedIn',
                icon: Icons.link_rounded,
                onTap: () => _launchURL(data['linkedinUrl']),
                color: Colors.blue.shade600,
              ),
            if (data['certificateUrl'] != null)
              _VerificationChip(
                label: 'Certificate',
                icon: Icons.verified_user_rounded,
                onTap: () => _launchURL(data['certificateUrl']),
                color: Colors.green.shade600,
              ),
            if (data['resumeUrl'] != null)
              _VerificationChip(
                label: 'Resume',
                icon: Icons.description_rounded,
                onTap: () => _launchURL(data['resumeUrl']),
                color: Colors.purple.shade600,
              ),
            if (data['linkedinUrl'] == null && data['certificateUrl'] == null && data['resumeUrl'] == null)
              Text('No documents provided', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _VerificationChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _VerificationChip({required this.label, required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
