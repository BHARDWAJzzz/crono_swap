import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_providers.dart';

class DonateCreditsPage extends ConsumerStatefulWidget {
  const DonateCreditsPage({super.key});

  @override
  ConsumerState<DonateCreditsPage> createState() => _DonateCreditsPageState();
}

class _DonateCreditsPageState extends ConsumerState<DonateCreditsPage> {
  int _donateAmount = 1;
  bool _isDonating = false;

  Future<void> _donate() async {
    final user = ref.read(userDataProvider).value;
    if (user == null) return;
    if (user.timeBalance < _donateAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isDonating = true);
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Deduct from user
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(user.id),
        {'timeBalance': FieldValue.increment(-_donateAmount)},
      );

      // Add to community pool
      batch.set(
        FirebaseFirestore.instance.collection('donations').doc(),
        {
          'donorId': user.id,
          'donorName': user.name,
          'amount': _donateAmount,
          'createdAt': Timestamp.now(),
        },
      );

      // Log transaction
      batch.set(
        FirebaseFirestore.instance.collection('transactions').doc(),
        {
          'userId': user.id,
          'otherUserId': 'community',
          'otherUserName': 'Community Pool',
          'title': 'Donated $_donateAmount Crono Hours',
          'amount': -_donateAmount,
          'type': 'donation',
          'createdAt': Timestamp.now(),
        },
      );

      // Award XP for generosity
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(user.id),
        {'xp': FieldValue.increment(25)},
      );

      await batch.commit();
      ref.invalidate(userDataProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💝 Thank you! $_donateAmount hours donated to the community. +25 XP!',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDonating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(userDataProvider).value;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Donate Credits', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade300, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Help Someone Learn',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Donate your Crono Hours to help underprivileged students access skill sessions for free.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Pool stats
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('donations').snapshots(),
              builder: (context, snapshot) {
                int totalDonated = 0;
                int totalDonors = 0;
                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  final donors = <String>{};
                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalDonated += (data['amount'] ?? 0) as int;
                    donors.add(data['donorId'] ?? '');
                  }
                  totalDonors = donors.length;
                }
                return Row(
                  children: [
                    Expanded(child: _buildStatCard('$totalDonated hrs', 'Total Donated', Icons.timer_outlined, Colors.purple)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('$totalDonors', 'Generous Donors', Icons.people_outlined, Colors.pink)),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),

            // Amount picker
            Text('HOW MANY HOURS?', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _donateAmount > 1 ? () => setState(() => _donateAmount--) : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 32),
                ),
                const SizedBox(width: 20),
                Text(
                  '$_donateAmount',
                  style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: _donateAmount < (user?.timeBalance ?? 0) ? () => setState(() => _donateAmount++) : null,
                  icon: const Icon(Icons.add_circle_outline, size: 32),
                ),
              ],
            ),
            Text('Your balance: ${user?.timeBalance ?? 0} hrs', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDonating ? null : _donate,
                icon: const Icon(Icons.favorite_rounded),
                label: Text(_isDonating ? 'Donating...' : 'Donate Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        ],
      ),
    );
  }
}
