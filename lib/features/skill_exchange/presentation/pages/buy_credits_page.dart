import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_providers.dart';
import 'admin_config_page.dart';

class BuyCreditsPage extends ConsumerStatefulWidget {
  const BuyCreditsPage({super.key});

  @override
  ConsumerState<BuyCreditsPage> createState() => _BuyCreditsPageState();
}

class _BuyCreditsPageState extends ConsumerState<BuyCreditsPage> {
  bool _isProcessing = false;

  Future<void> _handlePurchase(int hours, int priceINR, String razorpayKey) async {
    if (razorpayKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Razorpay is not configured yet'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // For now, simulate a successful purchase.
      // In production, use razorpay_flutter package:
      // final razorpay = Razorpay();
      // razorpay.open({
      //   'key': razorpayKey,
      //   'amount': priceINR * 100,
      //   'name': 'Crono Swap',
      //   'description': '$hours Crono Hours',
      //   'prefill': {'email': user.email},
      // });

      final user = ref.read(userDataProvider).value;
      if (user == null) return;

      // Award hours
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'timeBalance': FieldValue.increment(hours),
      });

      // Log transaction
      await FirebaseFirestore.instance.collection('transactions').doc().set({
        'userId': user.id,
        'otherUserId': 'system',
        'otherUserName': 'Credit Purchase',
        'title': 'Purchased $hours Crono Hours',
        'amount': hours,
        'type': 'income',
        'createdAt': Timestamp.now(),
      });

      ref.invalidate(userDataProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 $hours Crono Hours added to your balance!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Buy Crono Hours', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: configAsync.when(
        data: (config) {
          final packages = (config['creditPackages'] as List<dynamic>?) ?? [];
          final razorpayKey = config['razorpayKeyId'] ?? '';
          final enabled = config['razorpayEnabled'] ?? false;

          if (!enabled || packages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Credit store is not available yet',
                      style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The admin has not enabled in-app purchases.',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Top Up Your Balance',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Purchase Crono Hours to unlock more swaps and lectures.',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('CHOOSE A PACKAGE', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 2)),
                const SizedBox(height: 16),
                ...packages.map((pkg) {
                  final hours = pkg['hours'] ?? 0;
                  final price = pkg['priceINR'] ?? 0;
                  final isPopular = hours >= 10;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPopular ? theme.colorScheme.primary : Colors.grey.shade200,
                        width: isPopular ? 2 : 1,
                      ),
                      color: isPopular ? theme.colorScheme.primary.withValues(alpha: 0.03) : Colors.white,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${hours}h',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      title: Text('$hours Crono Hours', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '₹${(price / hours).toStringAsFixed(0)} per hour',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        onPressed: _isProcessing ? null : () => _handlePurchase(hours, price, razorpayKey),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text('₹$price', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
