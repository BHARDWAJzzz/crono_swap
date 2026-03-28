import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification service. Writes notification docs to Firestore.
/// No Cloud Functions needed — events are fired from repositories.
class AppNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a notification to a user
  Future<void> notify({
    required String userId,
    required String title,
    required String body,
    required String type, // swap_request, quest_posted, streak_warning, level_up, badge_earned
    String? relatedId, // swap ID, quest ID, etc.
    String? fromUserId,
    String? fromUserName,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }

  /// Get notification stream for a user
  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Get unread count stream
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final unread = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // --- Convenience methods for common events ---

  Future<void> onSwapRequested({
    required String receiverId,
    required String senderName,
    required String skillTitle,
    required String swapId,
    required String senderId,
  }) async {
    await notify(
      userId: receiverId,
      title: 'New Swap Request',
      body: '$senderName wants to learn $skillTitle from you!',
      type: 'swap_request',
      relatedId: swapId,
      fromUserId: senderId,
      fromUserName: senderName,
    );
  }

  Future<void> onSwapAccepted({
    required String senderId,
    required String receiverName,
    required String skillTitle,
    required String swapId,
    required String receiverId,
  }) async {
    await notify(
      userId: senderId,
      title: 'Swap Accepted! 🎉',
      body: '$receiverName accepted your request for $skillTitle',
      type: 'swap_accepted',
      relatedId: swapId,
      fromUserId: receiverId,
      fromUserName: receiverName,
    );
  }

  Future<void> onQuestPosted({
    required String questTitle,
    required int creditReward,
    required String questId,
    required List<String> targetUserIds,
    required String creatorName,
    required String creatorId,
  }) async {
    for (final userId in targetUserIds) {
      await notify(
        userId: userId,
        title: 'New Quest Available 🎯',
        body: '$questTitle — earn $creditReward credits',
        type: 'quest_posted',
        relatedId: questId,
        fromUserId: creatorId,
        fromUserName: creatorName,
      );
    }
  }

  Future<void> onLevelUp({
    required String userId,
    required int newLevel,
    required String levelTitle,
  }) async {
    await notify(
      userId: userId,
      title: 'Level Up! 🎉',
      body: 'You reached Level $newLevel — $levelTitle!',
      type: 'level_up',
    );
  }

  Future<void> onBadgeEarned({
    required String userId,
    required String badgeName,
    required String badgeEmoji,
  }) async {
    await notify(
      userId: userId,
      title: 'Badge Earned! $badgeEmoji',
      body: 'You earned the $badgeName badge!',
      type: 'badge_earned',
    );
  }

  Future<void> onStreakWarning({
    required String userId,
    required int currentStreak,
  }) async {
    await notify(
      userId: userId,
      title: 'Streak at Risk! 🔥',
      body: 'Your $currentStreak-day streak will reset tomorrow if you don\'t complete an activity.',
      type: 'streak_warning',
    );
  }
}
