import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/swap_request.dart';
import '../providers/swap_providers.dart';

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
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text('My Swaps', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Incoming'),
              Tab(text: 'Sent'),
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(swap.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    swap.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(swap.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(dateStr, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              swap.skillTitle,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              isIncoming ? 'From: ${swap.senderName}' : 'To: ${swap.receiverName}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            if (isIncoming && swap.status == SwapRequestStatus.pending) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(ref, swap.id, SwapRequestStatus.rejected),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade100),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Decline'),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            if (!isIncoming && swap.status == SwapRequestStatus.accepted) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(swapRepositoryProvider).completeRequest(swap.id),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Confirm Completion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateStatus(WidgetRef ref, String requestId, SwapRequestStatus status) {
    ref.read(swapRepositoryProvider).updateRequestStatus(requestId, status);
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
