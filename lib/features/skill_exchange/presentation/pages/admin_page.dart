import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/skill_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/scale_on_tap.dart';
import '../providers/auth_providers.dart';
import '../../domain/entities/user.dart';
import 'profile_page.dart';
import 'admin_config_page.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillListProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
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
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Content'),
              Tab(text: 'Onboarding'),
              Tab(text: 'Users'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildContentTab(theme, skillsAsync),
            _buildOnboardingTab(theme, ref),
            const _AdminUsersTab(),
            const _AdminReportsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminConfigPage())),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.settings_rounded),
          label: const Text('Config'),
        ),
      ),
    );
  }

  Widget _buildContentTab(ThemeData theme, AsyncValue<List<dynamic>> skillsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStats(theme, skillsAsync),
        _buildUserDistributionChart(theme),
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
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('skills').doc(skill.id).delete();
                      },
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

  /// Original onboarding approval tab — only shows pending users
  Widget _buildOnboardingTab(ThemeData theme, WidgetRef ref) {
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

            return InkWell(
              onTap: () {
                final user = AppUser.fromFirestore(data, userId);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(user: user)));
              },
              borderRadius: BorderRadius.circular(16),
              child: Card(
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
                      _VerificationLinks(data: data),
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('reports').where('status', isEqualTo: 'open').snapshots(),
            builder: (_, snap) => _buildStatItem('Reports', snap.data?.docs.length.toString() ?? '...'),
          ),
          const SizedBox(width: 40),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('isActive', isEqualTo: false).snapshots(),
            builder: (_, snap) => _buildStatItem('Suspended', snap.data?.docs.length.toString() ?? '0'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return ScaleOnTapWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
        ],
      ),
    );
  }

  Widget _buildUserDistributionChart(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        int approved = 0;
        int pending = 0;
        int suspended = 0;
        
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isActive'] == false || data['status'] == 'suspended') {
            suspended++;
          } else if (data['status'] == 'pending') {
            pending++;
          } else {
            approved++;
          }
        }
        
        final total = approved + pending + suspended;
        if (total == 0) return const SizedBox.shrink();

        return Container(
          height: 220,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.red.shade50,
          child: Row(
            children: [
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setChartState) {
                    int touchedIndex = -1;
                    return PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        pieTouchData: PieTouchData(
                          enabled: true,
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              setChartState(() {
                                touchedIndex = -1;
                              });
                              return;
                            }
                            setChartState(() {
                              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: () {
                          final sections = <PieChartSectionData>[];
                          if (approved > 0) {
                            final idx = sections.length;
                            sections.add(PieChartSectionData(
                              color: Colors.green.shade400,
                              value: approved.toDouble(),
                              title: '$approved',
                              radius: touchedIndex == idx ? 60 : 50,
                              titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ));
                          }
                          if (pending > 0) {
                            final idx = sections.length;
                            sections.add(PieChartSectionData(
                              color: Colors.orange.shade400,
                              value: pending.toDouble(),
                              title: '$pending',
                              radius: touchedIndex == idx ? 60 : 50,
                              titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ));
                          }
                          if (suspended > 0) {
                            final idx = sections.length;
                            sections.add(PieChartSectionData(
                              color: Colors.red.shade400,
                              value: suspended.toDouble(),
                              title: '$suspended',
                              radius: touchedIndex == idx ? 60 : 50,
                              titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ));
                          }
                          return sections;
                        }(),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 250),
                      swapAnimationCurve: Curves.easeInOut,
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(Colors.green.shade400, 'Approved'),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.orange.shade400, 'Pending'),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.red.shade400, 'Suspended'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return ScaleOnTapWidget(
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ----------- Users Tab -----------

class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab();

  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final docs = (snapshot.data?.docs ?? []).where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toLowerCase();
                final email = (data['email'] ?? '').toLowerCase();
                return _search.isEmpty || name.contains(_search) || email.contains(_search);
              }).toList();

              if (docs.isEmpty) {
                return Center(child: Text('No users found', style: TextStyle(color: Colors.grey.shade400)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final userId = docs[index].id;
                  final isActive = data['isActive'] ?? true;
                  final balance = (data['timeBalance'] ?? 0).toDouble();

                  return InkWell(
                    onTap: () {
                      final user = AppUser.fromFirestore(data, userId);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(user: user)));
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isActive ? Colors.grey.shade100 : Colors.red.shade100,
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: data['avatarUrl'] != null ? NetworkImage(data['avatarUrl']) : null,
                                  child: data['avatarUrl'] == null ? Text(
                                    (data['name'] ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(data['email'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isActive ? 'ACTIVE' : 'SUSPENDED',
                                    style: TextStyle(
                                      color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  '${balance.toStringAsFixed(1)} credits',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Text(
                                  'Level ${data['level'] ?? 1}',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _VerificationLinks(data: data),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showAddCreditDialog(context, userId, data['name'] ?? 'User', balance),
                                    icon: const Icon(Icons.add_card_rounded, size: 16),
                                    label: const Text('Credits'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue.shade700,
                                      side: BorderSide(color: Colors.blue.shade200),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _toggleUserActive(userId, isActive),
                                    icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 16),
                                    label: Text(isActive ? 'Suspend' : 'Restore'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isActive ? Colors.red.shade50 : Colors.green.shade50,
                                      foregroundColor: isActive ? Colors.red.shade700 : Colors.green.shade700,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _toggleUserActive(String userId, bool currentlyActive) async {
    final newValue = !currentlyActive;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'isActive': newValue});
  }

  void _showAddCreditDialog(BuildContext context, String userId, String userName, double currentBalance) {
    final controller = TextEditingController();
    String? note;
    bool isDeducting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Adjust Credits', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: $userName', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Text('Current: ${currentBalance.toStringAsFixed(1)} hrs', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              
              // Action Toggle
              Center(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Add'), icon: Icon(Icons.add_circle_outline_rounded)),
                    ButtonSegment(value: true, label: Text('Deduct'), icon: Icon(Icons.remove_circle_outline_rounded)),
                  ],
                  selected: {isDeducting},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setDialogState(() => isDeducting = newSelection.first);
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: isDeducting ? Colors.red.shade100 : Colors.green.shade100,
                    selectedForegroundColor: isDeducting ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                decoration: InputDecoration(
                  labelText: isDeducting ? 'Amount to Deduct' : 'Amount to Add',
                  prefixIcon: Icon(isDeducting ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: isDeducting ? 'Deducting from balance' : 'Adding to balance',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => note = v,
                decoration: InputDecoration(
                  labelText: 'Reason (optional)',
                  prefixIcon: const Icon(Icons.note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final inputAmount = double.tryParse(controller.text);
                if (inputAmount == null) return;
                
                final finalAmount = isDeducting ? -inputAmount.abs() : inputAmount.abs();
                
                await _adjustCredits(userId, finalAmount, note);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${isDeducting ? "Deducted" : "Added"} ${inputAmount.abs()} credits for $userName'),
                      backgroundColor: isDeducting ? Colors.red : Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDeducting ? Colors.red.shade700 : Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adjustCredits(String userId, double amount, String? reason) async {
    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    batch.update(userRef, {
      'timeBalance': FieldValue.increment(amount),
    });

    // Log the admin credit transaction
    final txRef = FirebaseFirestore.instance.collection('transactions').doc();
    batch.set(txRef, {
      'userId': userId,
      'type': 'adminAdjustment',
      'amount': amount,
      'description': reason ?? 'Admin credit adjustment',
      'createdAt': Timestamp.now(),
    });

    await batch.commit();
  }
}

// ----------- Reports Tab -----------

class _AdminReportsTab extends StatefulWidget {
  const _AdminReportsTab();

  @override
  State<_AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<_AdminReportsTab> {
  String _filter = 'open';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _filterChip('Open', 'open'),
              const SizedBox(width: 8),
              _filterChip('Resolved', 'resolved'),
              const SizedBox(width: 8),
              _filterChip('Dismissed', 'dismissed'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .where('status', isEqualTo: _filter)
                .orderBy('createdAt', descending: true)
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
                      Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green.shade200),
                      const SizedBox(height: 16),
                      Text('No $_filter reports 🎉', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final reportId = docs[index].id;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.orange.shade100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.flag_rounded, color: Colors.orange.shade700, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['reason'] ?? 'No reason given',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (createdAt != null)
                                      Text(
                                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (data['details'] != null && (data['details'] as String).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(data['details'], style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Reporter: ${data['reporterName'] ?? 'Anonymous'} • Against: ${data['reportedUserName'] ?? 'Unknown'}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                          if (_filter == 'open') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _updateReport(reportId, 'dismissed'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Dismiss'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _suspendReportedUser(context, data, reportId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Suspend User'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade700 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _updateReport(String reportId, String status) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'status': status});
  }

  Future<void> _suspendReportedUser(BuildContext context, Map<String, dynamic> reportData, String reportId) async {
    final reportedUserId = reportData['reportedUserId'];
    if (reportedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user ID found in report')));
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    batch.update(FirebaseFirestore.instance.collection('users').doc(reportedUserId), {'isActive': false});
    batch.update(FirebaseFirestore.instance.collection('reports').doc(reportId), {'status': 'resolved'});
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reportData['reportedUserName'] ?? 'User'} has been suspended and report resolved.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
class _VerificationLinks extends StatelessWidget {
  final Map<String, dynamic> data;
  const _VerificationLinks({required this.data});

  @override
  Widget build(BuildContext context) {
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
            if (data['linkedinUrl'] != null && data['linkedinUrl'].toString().isNotEmpty)
              _VerificationChip(
                label: 'LinkedIn',
                icon: Icons.link_rounded,
                onTap: () => _launchURL(data['linkedinUrl']),
                color: Colors.blue.shade600,
              ),
            if (data['certificateUrl'] != null && data['certificateUrl'].toString().isNotEmpty)
              _VerificationChip(
                label: 'Certificate',
                icon: Icons.verified_user_rounded,
                onTap: () => _launchURL(data['certificateUrl']),
                color: Colors.green.shade600,
              ),
            if (data['resumeUrl'] != null && data['resumeUrl'].toString().isNotEmpty)
              _VerificationChip(
                label: 'Resume',
                icon: Icons.description_rounded,
                onTap: () => _launchURL(data['resumeUrl']),
                color: Colors.purple.shade600,
              ),
            if ((data['linkedinUrl'] == null || data['linkedinUrl'].toString().isEmpty) && 
                (data['certificateUrl'] == null || data['certificateUrl'].toString().isEmpty) && 
                (data['resumeUrl'] == null || data['resumeUrl'].toString().isEmpty))
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
