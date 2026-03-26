import 'package:cloud_firestore/cloud_firestore.dart' as firebase;

/// Centralized XP + Level engine. All XP rewards are configurable via app_config.
class GamificationService {
  final firebase.FirebaseFirestore _firestore = firebase.FirebaseFirestore.instance;

  // Default XP values (overridden by app_config if available)
  static const int defaultXpPerSwap = 50;
  static const int defaultXpPerReview = 10;
  static const int defaultXpPerLecture = 30;
  static const int defaultStreakBonus = 20;

  /// Award XP to a user and recalculate their level.
  Future<void> awardXP(String userId, int amount) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() ?? {};

      final currentXP = (data['xp'] ?? 0) as int;
      final newXP = currentXP + amount;
      final newLevel = _calculateLevel(newXP);

      transaction.update(userRef, {
        'xp': newXP,
        'level': newLevel,
      });
    });
  }

  /// Award XP for completing a swap (to both participants).
  Future<void> onSwapCompleted(String userId1, String userId2, {int? xpOverride}) async {
    final xp = xpOverride ?? defaultXpPerSwap;
    await Future.wait([
      awardXP(userId1, xp),
      awardXP(userId2, xp),
    ]);
  }

  /// Award XP for selling a lecture.
  Future<void> onLectureSold(String sellerId, {int? xpOverride}) async {
    final xp = xpOverride ?? defaultXpPerLecture;
    await awardXP(sellerId, xp);
  }

  /// Increment streak for a user (called daily or weekly).
  Future<void> incrementStreak(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'streak': firebase.FieldValue.increment(1),
      'xp': firebase.FieldValue.increment(defaultStreakBonus),
    });
  }

  /// Reset streak if user missed a week.
  Future<void> resetStreak(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'streak': 0,
    });
  }

  /// Award a badge to a user.
  Future<void> awardBadge(String userId, String badgeId) async {
    await _firestore.collection('users').doc(userId).update({
      'badgeIds': firebase.FieldValue.arrayUnion([badgeId]),
    });
  }

  /// Calculate level from total XP. Each level requires level * 500 XP.
  int _calculateLevel(int totalXP) {
    int level = 1;
    int xpRequired = 500;
    int accumulated = 0;

    while (accumulated + xpRequired <= totalXP) {
      accumulated += xpRequired;
      level++;
      xpRequired = level * 500;
    }

    return level;
  }
}
