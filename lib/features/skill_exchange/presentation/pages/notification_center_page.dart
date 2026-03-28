import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/app_notification_service.dart';
import '../providers/auth_providers.dart';
import 'quest_detail_page.dart';
import 'chat_page.dart';
import '../../domain/entities/swap_request.dart';
import '../providers/swap_providers.dart';

class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(userDataProvider).value;
    final notificationService = AppNotificationService();

    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => notificationService.markAllAsRead(user.id),
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: notificationService.getNotifications(user.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text('All caught up!', style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['isRead'] ?? false;
              final createdAt = (notification['createdAt'] as Timestamp).toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isRead ? Colors.transparent : theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isRead ? Colors.grey.shade100 : theme.colorScheme.primary.withOpacity(0.1),
                  ),
                ),
                child: ListTile(
                  onTap: () async {
                    await notificationService.markAsRead(notification['id']);
                    _handleNotificationTap(context, ref, notification);
                  },
                  leading: _getNotificationIcon(notification['type']),
                  title: Text(
                    notification['title'] ?? '',
                    style: GoogleFonts.outfit(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notification['body'] ?? '',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(createdAt),
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ],
                  ),
                  trailing: !isRead 
                    ? Container(width: 8, height: 8, decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle))
                    : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getNotificationIcon(String? type) {
    switch (type) {
      case 'swap_request':
        return const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20));
      case 'swap_accepted':
        return const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 20));
      case 'quest_posted':
        return const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20));
      case 'level_up':
        return const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.trending_up_rounded, color: Colors.white, size: 20));
      case 'badge_earned':
        return const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20));
      default:
        return const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.notifications_rounded, color: Colors.white, size: 20));
    }
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, Map<String, dynamic> notification) {
    final type = notification['type'];
    final relatedId = notification['relatedId'];

    if (relatedId == null) return;

    if (type == 'swap_request' || type == 'swap_accepted') {
      // In a real app, you'd fetch the swap by ID and navigate to it
      // For now, let's toast
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening swap $relatedId')));
    } else if (type == 'quest_posted') {
      // Fetch quest and navigate
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening quest $relatedId')));
    }
  }
}
