import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/swap_request.dart';
import '../providers/swap_providers.dart';
import '../providers/auth_providers.dart';
import 'chat_page.dart';
import 'review_page.dart';

class SwapsPage extends ConsumerWidget {
  const SwapsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final incomingSwaps = ref.watch(incomingSwapsProvider);
    final outgoingSwaps = ref.watch(outgoingSwapsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('MY SWAPS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 4,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
            tabs: const [
              Tab(text: 'INCOMING'),
              Tab(text: 'SENT'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSwapList(context, ref, incomingSwaps, theme, isIncoming: true),
            _buildSwapList(context, ref, outgoingSwaps, theme, isIncoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapList(BuildContext context, WidgetRef ref, AsyncValue<List<SwapRequest>> swapsAsync, ThemeData theme, {required bool isIncoming}) {
    return swapsAsync.when(
      data: (swaps) {
        if (swaps.isEmpty) {
          return _buildEmptyState(
            isIncoming 
              ? 'No incoming requests yet. Post some skills to attract partners!' 
              : 'No requests sent yet. Explore the marketplace!'
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: swaps.length,
          itemBuilder: (context, index) {
            final swap = swaps[index];
            return _buildSwapCard(context, ref, swap, theme, isIncoming);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSwapCard(BuildContext context, WidgetRef ref, SwapRequest swap, ThemeData theme, bool isIncoming) {
    final dateStr = DateFormat('MMM d, HH:mm').format(swap.createdAt);
    final avatarUrl = isIncoming ? swap.senderAvatarUrl : swap.receiverAvatarUrl;
    final partnerName = isIncoming ? swap.senderName : swap.receiverName;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null ? const Icon(Icons.person) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partnerName.toUpperCase(),
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                            Text(
                              isIncoming ? 'Requested your skill' : 'You requested',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(swap.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          swap.status.name.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: _getStatusColor(swap.status),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          swap.skillTitle,
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${swap.timeValue.toStringAsFixed(1)} Hr',
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
                  const SizedBox(height: 8),
                  Text(
                    'RECEIVED ON: $dateStr',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                  if (swap.scheduledAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.event_available_rounded, size: 12, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'SCHEDULED: ${DateFormat('MMM d, HH:mm').format(swap.scheduledAt!)}',
                          style: TextStyle(color: Colors.green.shade600, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            if (isIncoming && swap.status == SwapRequestStatus.pending)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _updateStatus(ref, swap.id, SwapRequestStatus.rejected),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('DECLINE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(ref, swap.id, SwapRequestStatus.accepted),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),

            if (swap.status == SwapRequestStatus.accepted || swap.status == SwapRequestStatus.completed)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (c) => ChatPage(swap: swap)),
                        ),
                        icon: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: theme.colorScheme.primary),
                        label: Text('CHAT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 1)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    if (!isIncoming && swap.status == SwapRequestStatus.accepted) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ref.read(swapRepositoryProvider).completeRequest(swap.id),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text('COMPLETE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                    if (swap.status == SwapRequestStatus.completed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final user = ref.read(userDataProvider).value;
                            if (user == null) return;
                            final revieweeId = user.id == swap.senderId ? swap.receiverId : swap.senderId;
                            final revieweeName = user.id == swap.senderId ? swap.receiverName : swap.senderName;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewPage(
                                  swapId: swap.id,
                                  revieweeId: revieweeId,
                                  revieweeName: revieweeName,
                                  skillTitle: swap.skillTitle,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.star_border_rounded, size: 18),
                          label: const Text('REVIEW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            // Report button for accepted/completed swaps
            if (swap.status == SwapRequestStatus.accepted || swap.status == SwapRequestStatus.completed)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: TextButton.icon(
                  onPressed: () {
                    final user = ref.read(userDataProvider).value;
                    if (user == null) return;
                    final reportedId = user.id == swap.senderId ? swap.receiverId : swap.senderId;
                    final reportedName = user.id == swap.senderId ? swap.receiverName : swap.senderName;
                    _showReportDialog(context, user.id, user.name, reportedId, reportedName, swap.id);
                  },
                  icon: Icon(Icons.flag_outlined, size: 16, color: Colors.red.shade300),
                  label: Text('Report issue with this swap', style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(WidgetRef ref, String requestId, SwapRequestStatus status) {
    ref.read(swapRepositoryProvider).updateRequestStatus(requestId, status);
  }

  void _showReportDialog(BuildContext context, String reporterId, String reporterName, String reportedId, String reportedName, String swapId) {
    String? selectedReason;
    final detailsController = TextEditingController();
    final reasons = ['Did not show up', 'Incomplete session', 'Inappropriate behaviour', 'Fraud or scam', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reporting: $reportedName', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedReason,
                hint: const Text('Select a reason'),
                items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setDialogState(() => selectedReason = v),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Additional details (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedReason == null ? null : () async {
                await FirebaseFirestore.instance.collection('reports').add({
                  'reporterId': reporterId,
                  'reporterName': reporterName,
                  'reportedUserId': reportedId,
                  'reportedUserName': reportedName,
                  'swapId': swapId,
                  'reason': selectedReason,
                  'details': detailsController.text.trim(),
                  'status': 'open',
                  'createdAt': Timestamp.now(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted. Our team will review it.'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SwapRequestStatus status) {
    switch (status) {
      case SwapRequestStatus.pending: return Colors.orange;
      case SwapRequestStatus.accepted: return Colors.green;
      case SwapRequestStatus.rejected: return Colors.red;
      case SwapRequestStatus.completed: return Colors.blue;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horizontal_circle_outlined, size: 80, color: Colors.grey.shade100),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
